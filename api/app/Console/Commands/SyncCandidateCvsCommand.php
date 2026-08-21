<?php

namespace App\Console\Commands;

use App\Jobs\SyncCandidateCvsJob;
use App\Services\JneHojaVidaService;
use Illuminate\Console\Command;

class SyncCandidateCvsCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'jne:sync-candidate-cvs 
                            {--chunk=50 : Tamaño de bloque de candidatos por lote}
                            {--delay=250 : Retardo en milisegundos entre peticiones para prevenir 429}
                            {--limit= : Límite máximo de candidatos a procesar (opcional)}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Descarga y enriquece las Hojas de Vida oficiales de candidatos desde JNE Declara con prevención de rate limit';

    /**
     * Execute the console command.
     */
    public function handle(JneHojaVidaService $cvService): int
    {
        $chunk = (int) $this->option('chunk');
        $delay = (int) $this->option('delay');
        $limit = $this->option('limit') ? (int) $this->option('limit') : null;

        $this->info("Iniciando sincronización de Hojas de Vida JNE (Chunk: {$chunk}, Delay: {$delay}ms, Límite: " . ($limit ?: 'TODOS') . ")...");

        $job = new SyncCandidateCvsJob($chunk, $delay, $limit);
        $job->handle($cvService);

        $this->info("Sincronización finalizada exitosamente.");

        return Command::SUCCESS;
    }
}
