<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\PoliticalOrganization;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * @tags Organizaciones Políticas
 */
class PoliticalOrganizationController extends Controller
{
    /**
     * Listar y Buscar Organizaciones Políticas
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->input('per_page', 15), 100);
        if ($perPage < 1) {
            $perPage = 15;
        }

        $query = PoliticalOrganization::query();

        if ($search = $request->input('search')) {
            $search = trim($search);
            $like = config('database.default') === 'pgsql' ? 'ILIKE' : 'LIKE';
            $query->where(function ($q) use ($search, $like) {
                $q->where('name', $like, "%{$search}%")
                  ->orWhere('short_name', $like, "%{$search}%")
                  ->orWhere('org_type', $like, "%{$search}%");
            });
        }

        if ($request->boolean('all') || $request->input('paginate') === 'false') {
            $allOrgs = $query->orderBy('name')->get()->map(fn ($org) => [
                'id'             => $org->id,
                'jee_id'         => $org->jee_id,
                'name'           => $org->name,
                'short_name'     => $org->short_name,
                'org_type'       => $org->org_type ?? 'PARTIDO POLÍTICO',
                'logo_url'       => $this->resolveLogoUrl($org),
                'raw_logo_url'   => $org->logo_url,
                'local_logo_url' => $org->local_logo_url,
            ]);

            return response()->json([
                'message' => 'Lista de organizaciones políticas obtenida exitosamente.',
                'data'    => $allOrgs,
            ]);
        }

        $paginated = $query->orderBy('name')->paginate($perPage);

        $items = collect($paginated->items())->map(function ($org) {
            $resolvedLogo = $this->resolveLogoUrl($org);

            return [
                'id'             => $org->id,
                'jee_id'         => $org->jee_id,
                'name'           => $org->name,
                'short_name'     => $org->short_name,
                'org_type'       => $org->org_type ?? 'PARTIDO POLÍTICO',
                'logo_url'       => $resolvedLogo,
                'raw_logo_url'   => $org->logo_url,
                'local_logo_url' => $org->local_logo_url,
                'created_at'     => $org->created_at?->toIso8601String(),
                'updated_at'     => $org->updated_at?->toIso8601String(),
            ];
        });

        return response()->json([
            'message' => 'Lista de organizaciones políticas obtenida exitosamente.',
            'data'    => $items,
            'meta'    => [
                'current_page' => $paginated->currentPage(),
                'last_page'    => $paginated->lastPage(),
                'per_page'     => $paginated->perPage(),
                'total'        => $paginated->total(),
                'has_more'     => $paginated->hasMorePages(),
            ],
        ]);
    }

    /**
     * Ver Detalle de Organización Política
     */
    public function show(int $id): JsonResponse
    {
        $org = PoliticalOrganization::findOrFail($id);

        return response()->json([
            'message' => 'Detalle de la organización política.',
            'data'    => [
                'id'             => $org->id,
                'jee_id'         => $org->jee_id,
                'name'           => $org->name,
                'short_name'     => $org->short_name,
                'org_type'       => $org->org_type ?? 'PARTIDO POLÍTICO',
                'logo_url'       => $this->resolveLogoUrl($org),
                'raw_logo_url'   => $org->logo_url,
                'local_logo_url' => $org->local_logo_url,
                'created_at'     => $org->created_at?->toIso8601String(),
                'updated_at'     => $org->updated_at?->toIso8601String(),
            ],
        ]);
    }

    /**
     * Crear Organización Política con subida de Logo convertida a .webp
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name'       => 'required|string|max:255',
            'short_name' => 'nullable|string|max:50',
            'org_type'   => 'nullable|string|max:50',
            'logo'       => 'nullable|image|mimes:jpeg,png,jpg,gif,webp,svg|max:5120',
            'logo_url'   => 'nullable|url|max:500',
        ]);

        $localLogoUrl = null;
        $logoUrl = $request->input('logo_url');

        if ($request->hasFile('logo') && $request->file('logo')->isValid()) {
            $localLogoUrl = $this->processAndStoreWebpLogo($request->file('logo'));
            $logoUrl = Storage::disk('political_organizationals')->url($localLogoUrl);
        }

        $org = PoliticalOrganization::create([
            'name'           => trim($request->input('name')),
            'short_name'     => $request->filled('short_name') ? trim($request->input('short_name')) : null,
            'org_type'       => $request->input('org_type', 'PARTIDO POLÍTICO'),
            'logo_url'       => $logoUrl,
            'local_logo_url' => $localLogoUrl,
        ]);

        Cache::forget('political_org_logos_map');
        Cache::forget('catalog:political_organizations');

        return response()->json([
            'message' => 'Organización política creada exitosamente.',
            'data'    => $org,
        ], 201);
    }

    /**
     * Actualizar Organización Política y reemplazar Logo a .webp
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $org = PoliticalOrganization::findOrFail($id);

        $request->validate([
            'name'       => 'nullable|string|max:255',
            'short_name' => 'nullable|string|max:50',
            'org_type'   => 'nullable|string|max:50',
            'logo'       => 'nullable|image|mimes:jpeg,png,jpg,gif,webp,svg|max:5120',
            'logo_url'   => 'nullable|url|max:500',
        ]);

        $dataToUpdate = [];

        if ($request->filled('name')) {
            $dataToUpdate['name'] = trim($request->input('name'));
        }
        if ($request->has('short_name')) {
            $dataToUpdate['short_name'] = $request->filled('short_name') ? trim($request->input('short_name')) : null;
        }
        if ($request->filled('org_type')) {
            $dataToUpdate['org_type'] = $request->input('org_type');
        }
        if ($request->filled('logo_url')) {
            $dataToUpdate['logo_url'] = $request->input('logo_url');
        }

        if ($request->hasFile('logo') && $request->file('logo')->isValid()) {
            $localLogoUrl = $this->processAndStoreWebpLogo($request->file('logo'), $org->id);
            $dataToUpdate['local_logo_url'] = $localLogoUrl;
            $dataToUpdate['logo_url'] = Storage::disk('political_organizationals')->url($localLogoUrl);
        }

        $org->update($dataToUpdate);

        Cache::forget('political_org_logos_map');
        Cache::forget('catalog:political_organizations');

        return response()->json([
            'message' => 'Organización política actualizada exitosamente.',
            'data'    => $org,
        ]);
    }

    /**
     * Eliminar Organización Política
     */
    public function destroy(int $id): JsonResponse
    {
        $org = PoliticalOrganization::findOrFail($id);

        if ($org->local_logo_url && Storage::disk('political_organizationals')->exists($org->local_logo_url)) {
            Storage::disk('political_organizationals')->delete($org->local_logo_url);
        }

        $org->delete();

        Cache::forget('political_org_logos_map');
        Cache::forget('catalog:political_organizations');

        return response()->json([
            'message' => 'Organización política eliminada exitosamente.',
        ]);
    }

    /**
     * Procesa la imagen subida con Imagick / GD y la convierte a .webp
     */
    private function processAndStoreWebpLogo($uploadedFile, ?int $orgId = null): string
    {
        $disk = Storage::disk('political_organizationals');
        $filename = ($orgId ? $orgId : (string) Str::uuid()) . '_' . time() . '.webp';

        $realPath = $uploadedFile->getRealPath();

        // 1. Intentar con Imagick si la extensión está activa
        if (class_exists('\Imagick')) {
            try {
                $imagick = new \Imagick($realPath);
                $imagick->setImageFormat('webp');
                $imagick->setImageCompressionQuality(85);
                $webpData = $imagick->getImageBlob();
                $imagick->clear();
                $imagick->destroy();

                $disk->put($filename, $webpData);
                return $filename;
            } catch (\Throwable $e) {
                // Fallback a GD
            }
        }

        // 2. Fallback robusto con GD (imagewebp)
        $rawContent = file_get_contents($realPath);
        $image = @imagecreatefromstring($rawContent);
        if ($image !== false) {
            ob_start();
            imagepalettetotruecolor($image);
            imagealphablending($image, true);
            imagesavealpha($image, true);
            imagewebp($image, null, 85);
            $webpData = ob_get_clean();
            imagedestroy($image);

            $disk->put($filename, $webpData);
            return $filename;
        }

        // 3. Fallback directo si no se pudo convertir
        $ext = $uploadedFile->getClientOriginalExtension() ?: 'png';
        $fallbackName = ($orgId ? $orgId : (string) Str::uuid()) . '_' . time() . '.' . $ext;
        $disk->putFileAs('', $uploadedFile, $fallbackName);
        return $fallbackName;
    }

    /**
     * Resuelve la URL pública accesible del logo
     */
    private function resolveLogoUrl(PoliticalOrganization $org): ?string
    {
        $base = request()->getSchemeAndHttpHost();

        if ($org->local_logo_url) {
            $disk = Storage::disk('political_organizationals');
            if ($disk->exists($org->local_logo_url)) {
                return $base . '/storage/political-organizationals/' . $org->local_logo_url;
            }
        }

        if ($org->logo_url) {
            if (str_starts_with($org->logo_url, 'http://localhost/storage/')) {
                return str_replace('http://localhost/storage/', $base . '/storage/', $org->logo_url);
            }
            if (str_starts_with($org->logo_url, '/storage/')) {
                return $base . $org->logo_url;
            }
            return $org->logo_url;
        }

        return null;
    }
}
