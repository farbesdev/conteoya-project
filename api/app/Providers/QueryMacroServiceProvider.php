<?php

namespace App\Providers;

use Illuminate\Database\Eloquent\Builder as EloquentBuilder;
use Illuminate\Support\ServiceProvider;

class QueryMacroServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        $this->registerInsensitiveSearchMacros();
    }

    /**
     * Registrar macros de búsqueda case-insensitive agnósticas del SGBD (PostgreSQL, SQLite, MySQL).
     */
    protected function registerInsensitiveSearchMacros(): void
    {
        // 1. Eloquent Builder: whereAnyInsensitive
        EloquentBuilder::macro('whereAnyInsensitive', function (array $columns, ?string $value) {
            /** @var EloquentBuilder $this */
            $clean = trim((string) $value);
            if ($clean === '' || empty($columns)) {
                return $this;
            }

            $lowerValue = mb_strtolower($clean, 'UTF-8');
            $words = array_values(array_filter(explode(' ', $lowerValue), fn($w) => mb_strlen($w) > 0));

            return $this->where(function ($query) use ($columns, $lowerValue, $words) {
                // Coincidencia de la frase completa
                $query->where(function ($phraseQ) use ($columns, $lowerValue) {
                    foreach ($columns as $index => $column) {
                        $method = $index === 0 ? 'whereRaw' : 'orWhereRaw';
                        $phraseQ->{$method}("LOWER({$column}) LIKE ?", ["%{$lowerValue}%"]);
                    }
                });

                // Si hay múltiples palabras (ej. "Juan Perez"), buscar que todas estén presentes
                if (count($words) > 1) {
                    $query->orWhere(function ($multiQ) use ($columns, $words) {
                        foreach ($words as $word) {
                            $multiQ->where(function ($wordQ) use ($columns, $word) {
                                foreach ($columns as $index => $column) {
                                    $method = $index === 0 ? 'whereRaw' : 'orWhereRaw';
                                    $wordQ->{$method}("LOWER({$column}) LIKE ?", ["%{$word}%"]);
                                }
                            });
                        }
                    });
                }
            });
        });

        // 2. Eloquent Builder: orWhereAnyInsensitive
        EloquentBuilder::macro('orWhereAnyInsensitive', function (array $columns, ?string $value) {
            /** @var EloquentBuilder $this */
            $clean = trim((string) $value);
            if ($clean === '' || empty($columns)) {
                return $this;
            }

            $lowerValue = mb_strtolower($clean, 'UTF-8');
            $words = array_values(array_filter(explode(' ', $lowerValue), fn($w) => mb_strlen($w) > 0));

            return $this->orWhere(function ($query) use ($columns, $lowerValue, $words) {
                $query->where(function ($phraseQ) use ($columns, $lowerValue) {
                    foreach ($columns as $index => $column) {
                        $method = $index === 0 ? 'whereRaw' : 'orWhereRaw';
                        $phraseQ->{$method}("LOWER({$column}) LIKE ?", ["%{$lowerValue}%"]);
                    }
                });

                if (count($words) > 1) {
                    $query->orWhere(function ($multiQ) use ($columns, $words) {
                        foreach ($words as $word) {
                            $multiQ->where(function ($wordQ) use ($columns, $word) {
                                foreach ($columns as $index => $column) {
                                    $method = $index === 0 ? 'whereRaw' : 'orWhereRaw';
                                    $wordQ->{$method}("LOWER({$column}) LIKE ?", ["%{$word}%"]);
                                }
                            });
                        }
                    });
                }
            });
        });
    }
}
