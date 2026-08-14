<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Traits\MigrationSeedingMethod;
use App\Support\CSVProcessor;

class PollingStationSeeder extends Seeder
{
    use MigrationSeedingMethod;

    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $csvPath = base_path('../files/resultado_mesas.csv');
        if (!file_exists($csvPath)) {
            $csvPath = base_path('files/resultado_mesas.csv');
        }

        if (!file_exists($csvPath)) {
            $this->command?->error("Archivo CSV no encontrado en $csvPath.");
            return;
        }

        $this->command?->info("Cargando mesas desde $csvPath...");

        $rows = CSVProcessor::file($csvPath)->getRowsAsLazyCollection();

        if ($rows->isEmpty()) {
            $this->command?->error("El archivo CSV no contiene registros.");
            return;
        }

        $now = now()->toDateTimeString();
        $batch = [];
        $columns = [
            'code',
            'registered_voters',
            'status',
            'odpe',
            'pdf_file',
            'pdf_page',
            'department_name',
            'province_name',
            'district_name',
            'created_at',
            'updated_at',
        ];

        $count = 0;
        foreach ($rows as $row) {
            $code = !empty($row['codigo_mesa']) ? (string) $row['codigo_mesa'] : null;

            $batch[] = [
                'code'              => $code,
                'registered_voters' => 300,
                'status'            => 'ACTIVE',
                'odpe'              => !empty($row['odpe']) ? (string)$row['odpe'] : null,
                'pdf_file'          => !empty($row['archivo']) ? (string)$row['archivo'] : null,
                'pdf_page'          => isset($row['pagina']) && $row['pagina'] !== '' ? (int)$row['pagina'] : null,
                'department_name'   => !empty($row['departamento']) ? (string)$row['departamento'] : null,
                'province_name'     => !empty($row['provincia']) ? (string)$row['provincia'] : null,
                'district_name'     => !empty($row['distrito']) ? (string)$row['distrito'] : null,
                'created_at'        => $now,
                'updated_at'        => $now,
            ];

            $count++;

            if (count($batch) >= 2000) {
                $this->batchInsertOrUpdate(
                    'polling_stations',
                    $columns,
                    $batch,
                    [
                        'matchColumns'  => ['code'],
                        'updateColumns' => ['odpe', 'pdf_file', 'pdf_page', 'department_name', 'province_name', 'district_name', 'updated_at'],
                        'chunkSize'     => 1000,
                        'verbose'       => false,
                    ]
                );
                $this->command?->info("Procesadas $count filas...");
                $batch = [];
            }
        }

        if (!empty($batch)) {
            $this->batchInsertOrUpdate(
                'polling_stations',
                $columns,
                $batch,
                [
                    'matchColumns'  => ['code'],
                    'updateColumns' => ['odpe', 'pdf_file', 'pdf_page', 'department_name', 'province_name', 'district_name', 'updated_at'],
                    'chunkSize'     => 1000,
                    'verbose'       => false,
                ]
            );
            $this->command?->info("Procesadas $count filas en total.");
        }

        $this->command?->info("✓ Importación de mesas (PollingStationSeeder) completada con éxito ($count mesas).");
    }
}
