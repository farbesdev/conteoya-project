<?php

declare(strict_types=1);

namespace App\Traits;

use Illuminate\Support\Facades\DB;

trait MigrationSeedingMethod
{
    /**
     * Bulk-insert rows; silently skip duplicates based on a unique constraint.
     *
     * @param  string  $table  The name of the table.
     * @param  array  $columns  The columns to be inserted.
     * @param  array  $rows  The actual data rows (indexed arrays).
     * @param  array  $options  ['conflictColumns' => ['external_id'], 'chunkSize' => 500]
     */
    protected function insertOnConflictDoNothing(
        string $table,
        array $columns,
        array $rows,
        array $options = []
    ): void {
        if (empty($rows)) {
            return;
        }

        $conflictColumns = $options['conflictColumns'] ?? ['external_id'];
        $chunkSize       = $options['chunkSize'] ?? 500;
        $isPg = $this->isPostgres();
        $isSqlite = $this->isSqlite();

        foreach (array_chunk($rows, $chunkSize) as $chunk) {
            $data = $this->buildBulkPlaceholders($chunk, $columns);

            if ($isPg || $isSqlite) {
                $sql = sprintf(
                    'INSERT INTO %s (%s) VALUES %s ON CONFLICT (%s) DO NOTHING',
                    $this->q($table),
                    implode(', ', array_map([$this, 'q'], $columns)),
                    $data['placeholders'],
                    implode(', ', array_map([$this, 'q'], $conflictColumns))
                );
            } else {
                // MySQL: INSERT IGNORE
                $sql = sprintf(
                    'INSERT IGNORE INTO %s (%s) VALUES %s',
                    $this->q($table),
                    implode(', ', array_map([$this, 'q'], $columns)),
                    $data['placeholders']
                );
            }

            DB::statement($sql, $data['values']);
        }
    }

    /**
     * Bulk-insert rows; on conflict update the specified columns.
     *
     * @param  array  $options  ['conflictColumns' => ['external_id'], 'updateColumns' => [], 'chunkSize' => 500]
     */
    protected function upsert(
        string $table,
        array $columns,
        array $rows,
        array $options
    ): void {
        if (empty($rows)) {
            return;
        }

        $conflictColumns = $options['conflictColumns'] ?? ['external_id'];
        $updateColumns = $options['updateColumns']; // Required
        $chunkSize = $options['chunkSize'] ?? 500;
        $isPg = $this->isPostgres();

        if ($isPg) {
            $updateSet = implode(', ', array_map(function ($col) {
                return sprintf('%s = EXCLUDED.%s', $this->q($col), $this->q($col));
            }, $updateColumns));
        } else {
            $updateSet = implode(', ', array_map(function ($col) {
                return sprintf('%s = VALUES(%s)', $this->q($col), $this->q($col));
            }, $updateColumns));
        }

        foreach (array_chunk($rows, $chunkSize) as $chunk) {
            $data = $this->buildBulkPlaceholders($chunk, $columns);

            if ($isPg) {
                $sql = sprintf(
                    'INSERT INTO %s (%s) VALUES %s ON CONFLICT (%s) DO UPDATE SET %s',
                    $this->q($table),
                    implode(', ', array_map([$this, 'q'], $columns)),
                    $data['placeholders'],
                    implode(', ', array_map([$this, 'q'], $conflictColumns)),
                    $updateSet
                );
            } else {
                // MySQL: INSERT ... ON DUPLICATE KEY UPDATE
                $sql = sprintf(
                    'INSERT INTO %s (%s) VALUES %s ON DUPLICATE KEY UPDATE %s',
                    $this->q($table),
                    implode(', ', array_map([$this, 'q'], $columns)),
                    $data['placeholders'],
                    $updateSet
                );
            }

            DB::statement($sql, $data['values']);
        }
    }

    /**
     * Insert ONE row and return its generated PK.
     *
     * @param  array  $options  ['conflictColumns' => ['external_id'], 'returning' => 'id']
     */
    protected function insertGetId(
        string $table,
        array $columns,
        array $row,
        array $options = []
    ): int {
        $conflictColumns = $options['conflictColumns'] ?? ['external_id'];
        $returning = $options['returning'] ?? 'id';
        $placeholders = implode(', ', array_fill(0, count($row), '?'));
        $isPg = $this->isPostgres();

        if ($isPg) {
            $sql = sprintf(
                'INSERT INTO %s (%s) VALUES (%s) ON CONFLICT (%s) DO NOTHING RETURNING %s',
                $this->q($table),
                implode(', ', array_map([$this, 'q'], $columns)),
                $placeholders,
                implode(', ', array_map([$this, 'q'], $conflictColumns)),
                $this->q($returning)
            );

            $inserted = DB::select($sql, $row);

            if (! empty($inserted)) {
                return (int) $inserted[0]->{$returning};
            }
        } else {
            // MySQL: INSERT IGNORE + LAST_INSERT_ID()
            $sql = sprintf(
                'INSERT IGNORE INTO %s (%s) VALUES (%s)',
                $this->q($table),
                implode(', ', array_map([$this, 'q'], $columns)),
                $placeholders
            );

            DB::statement($sql, $row);
            $insertedId = (int) DB::getPdo()->lastInsertId();

            if ($insertedId > 0) {
                return $insertedId;
            }
        }

        // Fallback: la fila ya existía, buscarla por conflictColumns
        $conditions = $this->buildConditionsFromRow($columns, $row, $conflictColumns);

        return $this->selectGetFirstValue($table, $conditions, $returning);
    }

    /**
     * Insert OR update ONE row and always return the PK.
     *
     * @param  array  $options  ['conflictColumns' => ['external_id'], 'updateColumns' => [], 'returning' => 'id']
     */
    protected function upsertGetId(
        string $table,
        array $columns,
        array $row,
        array $options
    ): int {
        $conflictColumns = $options['conflictColumns'] ?? ['external_id'];
        $updateColumns = $options['updateColumns'];
        $returning = $options['returning'] ?? 'id';
        $placeholders = implode(', ', array_fill(0, count($row), '?'));
        $isPg = $this->isPostgres();

        if ($isPg) {
            $updateSet = implode(', ', array_map(function ($col) {
                return sprintf('%s = EXCLUDED.%s', $this->q($col), $this->q($col));
            }, $updateColumns));

            $sql = sprintf(
                'INSERT INTO %s (%s) VALUES (%s) ON CONFLICT (%s) DO UPDATE SET %s RETURNING %s',
                $this->q($table),
                implode(', ', array_map([$this, 'q'], $columns)),
                $placeholders,
                implode(', ', array_map([$this, 'q'], $conflictColumns)),
                $updateSet,
                $this->q($returning)
            );

            $result = DB::select($sql, $row);

            return (int) $result[0]->{$returning};
        } else {
            // MySQL: ON DUPLICATE KEY UPDATE + LAST_INSERT_ID()
            $updateSet = implode(', ', array_map(function ($col) {
                return sprintf('%s = VALUES(%s)', $this->q($col), $this->q($col));
            }, $updateColumns));

            $sql = sprintf(
                'INSERT INTO %s (%s) VALUES (%s) ON DUPLICATE KEY UPDATE %s',
                $this->q($table),
                implode(', ', array_map([$this, 'q'], $columns)),
                $placeholders,
                $updateSet
            );

            DB::statement($sql, $row);

            return (int) DB::getPdo()->lastInsertId();
        }
    }

    /**
     * Fetch the first row matching the given conditions object.
     *
     * @param  string  $select  Default '*'
     */
    protected function selectGetFirst(
        string $table,
        array $conditions,
        string $select = '*'
    ): ?object {
        $keys = array_keys($conditions);
        $values = array_values($conditions);
        $where = implode(' AND ', array_map(function ($key) {
            return sprintf('%s = ?', $this->q($key));
        }, $keys));

        $sql = sprintf(
            'SELECT %s FROM %s WHERE %s LIMIT 1',
            $select,
            $this->q($table),
            $where
        );

        $rows = DB::select($sql, $values);

        return $rows[0] ?? null;
    }

    /**
     * Insert many rows and collect all returned PKs in order.
     *
     * @param  array  $options  ['conflictColumns' => ['external_id'], 'returning' => 'id', 'chunkSize' => 500]
     */
    protected function insertBulkGetIds(
        string $table,
        array $columns,
        array $rows,
        array $options = []
    ): array {
        $conflictColumns = $options['conflictColumns'] ?? ['external_id'];
        $returning = $options['returning'] ?? 'id';
        $chunkSize = $options['chunkSize'] ?? 500;
        $ids = [];
        $isPg = $this->isPostgres();

        foreach (array_chunk($rows, $chunkSize) as $chunk) {
            $data = $this->buildBulkPlaceholders($chunk, $columns);

            if ($isPg) {
                $sql = sprintf(
                    'INSERT INTO %s (%s) VALUES %s ON CONFLICT (%s) DO NOTHING RETURNING %s',
                    $this->q($table),
                    implode(', ', array_map([$this, 'q'], $columns)),
                    $data['placeholders'],
                    implode(', ', array_map([$this, 'q'], $conflictColumns)),
                    $this->q($returning)
                );

                $inserted = DB::select($sql, $data['values']);

                if (count($inserted) < count($chunk)) {
                    foreach ($chunk as $row) {
                        $conditions = $this->buildConditionsFromRow($columns, $row, $conflictColumns);
                        $id = $this->selectGetFirstValue($table, $conditions, $returning);
                        if (! in_array($id, $ids)) {
                            $ids[] = $id;
                        }
                    }
                } else {
                    foreach ($inserted as $r) {
                        $ids[] = (int) $r->{$returning};
                    }
                }
            } else {
                $sqlIgnore = sprintf(
                    'INSERT IGNORE INTO %s (%s) VALUES %s',
                    $this->q($table),
                    implode(', ', array_map([$this, 'q'], $columns)),
                    $data['placeholders']
                );

                DB::statement($sqlIgnore, $data['values']);

                $conflictValues = [];
                $conflictIdx = [];
                foreach ($conflictColumns as $cc) {
                    $idx = array_search($cc, $columns);
                    if ($idx !== false) {
                        $conflictIdx[$cc] = $idx;
                    }
                }

                foreach ($chunk as $row) {
                    $vals = [];
                    foreach ($conflictIdx as $cc => $idx) {
                        $vals[] = $row[$idx];
                    }
                    $conflictValues[] = count($vals) === 1 ? $vals[0] : $vals;
                }

                if (count($conflictColumns) === 1) {
                    $flatValues = array_map(function ($v) {
                        return is_array($v) ? $v[0] : $v;
                    }, $conflictValues);
                    $idsFromChunk = $this->selectWhereIn($table, $conflictColumns[0], $flatValues, $returning);
                    foreach ($idsFromChunk as $id) {
                        if (! in_array($id, $ids)) {
                            $ids[] = $id;
                        }
                    }
                } else {
                    foreach ($chunk as $row) {
                        $conditions = $this->buildConditionsFromRow($columns, $row, $conflictColumns);
                        $id = $this->selectGetFirstValue($table, $conditions, $returning);
                        if (! in_array($id, $ids)) {
                            $ids[] = $id;
                        }
                    }
                }
            }
        }

        return $ids;
    }

    /**
     * Massive inserts tracking progress cleanly.
     *
     * @param  array  $options  ['conflictColumn' => 'code', 'chunkSize' => 500, 'verbose' => true]
     * @return array ['total' => int, 'chunks' => int]
     */
    protected function batchInsert(
        string $table,
        array $columns,
        array $rows,
        array $options = []
    ): array {
        if (empty($rows)) {
            return ['total' => 0, 'chunks' => 0];
        }

        $conflictColumn = $options['conflictColumn'] ?? 'code';
        $chunkSize      = $options['chunkSize'] ?? 500;
        $verbose        = $options['verbose'] ?? true;
        $isPg = $this->isPostgres();
        $isSqlite = $this->isSqlite();

        $chunks = array_chunk($rows, $chunkSize);
        $totalRows = count($rows);
        $insertedRows = 0;

        foreach ($chunks as $i => $chunk) {
            $data = $this->buildBulkPlaceholders($chunk, $columns);

            if ($isPg || $isSqlite) {
                $sql = sprintf(
                    'INSERT INTO %s (%s) VALUES %s ON CONFLICT (%s) DO NOTHING',
                    $this->q($table),
                    implode(', ', array_map([$this, 'q'], $columns)),
                    $data['placeholders'],
                    $this->q($conflictColumn)
                );
            } else {
                $sql = sprintf(
                    'INSERT IGNORE INTO %s (%s) VALUES %s',
                    $this->q($table),
                    implode(', ', array_map([$this, 'q'], $columns)),
                    $data['placeholders']
                );
            }

            DB::statement($sql, $data['values']);

            $insertedRows += count($chunk);

            if ($verbose) {
                $pct = round(($insertedRows / $totalRows) * 100);
                $this->info(sprintf(
                    '  [%s] chunk %d/%d — %d/%d rows (%d%%)',
                    $table,
                    $i + 1,
                    count($chunks),
                    $insertedRows,
                    $totalRows,
                    $pct
                ));
            }
        }

        return ['total' => $totalRows, 'chunks' => count($chunks)];
    }

    /**
     * Batch insert and resolve IDs to a Map.
     *
     * @param  array  $options  ['keyColumn' => 'code', 'idColumn' => 'id', 'chunkSize' => 500, 'verbose' => true]
     * @return array Associate array of key => id
     */
    protected function batchInsertAndResolveIds(
        string $table,
        array $columns,
        array $rows,
        array $options = []
    ): array {
        $keyColumn = $options['keyColumn'] ?? 'code';
        $idColumn = $options['idColumn'] ?? 'id';
        $chunkSize = $options['chunkSize'] ?? 500;
        $verbose = $options['verbose'] ?? true;

        $this->batchInsert($table, $columns, $rows, [
            'conflictColumn' => $keyColumn,
            'chunkSize' => $chunkSize,
            'verbose' => $verbose,
        ]);

        $keyIndex = array_search($keyColumn, $columns);
        $keyValues = array_map(function ($row) use ($keyIndex) {
            return (string) $row[$keyIndex];
        }, $rows);

        return $this->selectWhereIn($table, $keyColumn, $keyValues, $idColumn);
    }

    /**
     * Select multiple rows by IN clause.
     *
     * @param  string  $selectColumn  Default 'id'
     * @return array associative [key => id]
     */
    protected function selectWhereIn(
        string $table,
        string $keyColumn,
        array $keyValues,
        string $selectColumn = 'id'
    ): array {
        if (empty($keyValues)) {
            return [];
        }

        $isPg = $this->isPostgres();

        if ($isPg) {
            $sql = sprintf(
                'SELECT %s, %s FROM %s WHERE %s = ANY(?)',
                $this->q($keyColumn),
                $this->q($selectColumn),
                $this->q($table),
                $this->q($keyColumn)
            );

            $pgArray = '{'.implode(',', $keyValues).'}';
            $rows = DB::select($sql, [$pgArray]);
        } else {
            $placeholders = implode(',', array_fill(0, count($keyValues), '?'));
            $sql = sprintf(
                'SELECT %s, %s FROM %s WHERE %s IN (%s)',
                $this->q($keyColumn),
                $this->q($selectColumn),
                $this->q($table),
                $this->q($keyColumn),
                $placeholders
            );

            $rows = DB::select($sql, $keyValues);
        }

        $result = [];
        foreach ($rows as $r) {
            $result[(string) $r->{$keyColumn}] = (int) $r->{$selectColumn};
        }

        return $result;
    }

    /**
     * Single insert or update using CTE (PostgreSQL) or INSERT...ON DUPLICATE KEY UPDATE (MySQL).
     *
     * @param  array  $data  Associative array of col => val
     * @param  array  $options  ['matchColumns' => [], 'updateColumns' => [], 'returning' => 'id']
     */
    protected function insertOrUpdate(
        string $table,
        array $data,
        array $options
    ): int {
        $matchColumns = $options['matchColumns'];
        $updateColumns = $options['updateColumns'];
        $returning = $options['returning'] ?? 'id';
        $isPg = $this->isPostgres();

        $allColumns = array_keys($data);

        if ($isPg) {
            $setClause = implode(', ', array_map(function ($col) {
                return sprintf('%s = ?', $this->q($col));
            }, $updateColumns));

            $whereClause = implode(' AND ', array_map(function ($col) {
                return sprintf('%s = ?', $this->q($col));
            }, $matchColumns));

            $insertCols = implode(', ', array_map([$this, 'q'], $allColumns));
            $insertVals = implode(', ', array_fill(0, count($allColumns), '?'));

            $sql = "
                WITH updated AS (
                    UPDATE {$this->q($table)}
                    SET {$setClause}
                    WHERE {$whereClause}
                    RETURNING {$this->q($returning)}
                ),
                inserted AS (
                    INSERT INTO {$this->q($table)} ({$insertCols})
                    SELECT {$insertVals}
                    WHERE NOT EXISTS (SELECT 1 FROM updated)
                    RETURNING {$this->q($returning)}
                )
                SELECT {$this->q($returning)} FROM updated
                UNION ALL
                SELECT {$this->q($returning)} FROM inserted
            ";

            $bindings = [];
            foreach ($updateColumns as $col) {
                $bindings[] = $data[$col];
            }
            foreach ($matchColumns as $col) {
                $bindings[] = $data[$col];
            }
            foreach ($allColumns as $col) {
                $bindings[] = $data[$col];
            }

            $rows = DB::select($sql, $bindings);
        } else {
            $existing = $this->selectGetFirst($table, array_intersect_key($data, array_flip($matchColumns)), $this->q($returning));

            if ($existing) {
                $existingId = (int) $existing->{$returning};
                $setClause = implode(', ', array_map(function ($col) {
                    return sprintf('%s = ?', $this->q($col));
                }, $updateColumns));

                $whereClause = implode(' AND ', array_map(function ($col) {
                    return sprintf('%s = ?', $this->q($col));
                }, $matchColumns));

                $sql = sprintf(
                    'UPDATE %s SET %s WHERE %s',
                    $this->q($table),
                    $setClause,
                    $whereClause
                );

                $bindings = [];
                foreach ($updateColumns as $col) {
                    $bindings[] = $data[$col];
                }
                foreach ($matchColumns as $col) {
                    $bindings[] = $data[$col];
                }

                DB::statement($sql, $bindings);

                return $existingId;
            } else {
                $insertCols = implode(', ', array_map([$this, 'q'], $allColumns));
                $placeholders = implode(', ', array_fill(0, count($allColumns), '?'));
                $sql = sprintf('INSERT INTO %s (%s) VALUES (%s)', $this->q($table), $insertCols, $placeholders);
                DB::statement($sql, array_values($data));

                return (int) DB::getPdo()->lastInsertId();
            }
        }

        if (empty($rows)) {
            throw new \Exception(
                sprintf('[MigrationMethods.insertOrUpdate] No row affected in "%s". Check matchColumns [%s].', $table, implode(', ', $matchColumns))
            );
        }

        return (int) $rows[0]->{$returning};
    }

    /**
     * Bulk insert or update tracking progress.
     *
     * @param  array  $rows  Indexed arrays
     * @param  array  $options  ['matchColumns' => [], 'updateColumns' => [], 'chunkSize' => 500, 'verbose' => true]
     */
    protected function batchInsertOrUpdate(
        string $table,
        array $columns,
        array $rows,
        array $options
    ): void {
        if (empty($rows)) {
            return;
        }

        $matchColumns = $options['matchColumns'];
        $updateColumns = $options['updateColumns'];
        $chunkSize = $options['chunkSize'] ?? 500;
        $verbose = $options['verbose'] ?? true;
        $isPg = $this->isPostgres();
        $isSqlite = $this->isSqlite();

        $chunks = array_chunk($rows, $chunkSize);
        $totalRows = count($rows);

        foreach ($chunks as $i => $chunk) {
            $data = $this->buildBulkPlaceholders($chunk, $columns);

            if ($isPg || $isSqlite) {
                $setClause = implode(', ', array_map(function ($col) {
                    return sprintf('%s = EXCLUDED.%s', $this->q($col), $this->q($col));
                }, $updateColumns));

                $fullSql = sprintf(
                    'INSERT INTO %s (%s) VALUES %s ON CONFLICT (%s) DO UPDATE SET %s',
                    $this->q($table),
                    implode(', ', array_map([$this, 'q'], $columns)),
                    $data['placeholders'],
                    implode(', ', array_map([$this, 'q'], $matchColumns)),
                    $setClause
                );
            } else {
                $updateSet = implode(', ', array_map(function ($col) {
                    return sprintf('%s = VALUES(%s)', $this->q($col), $this->q($col));
                }, $updateColumns));

                $fullSql = sprintf(
                    'INSERT INTO %s (%s) VALUES %s ON DUPLICATE KEY UPDATE %s',
                    $this->q($table),
                    implode(', ', array_map([$this, 'q'], $columns)),
                    $data['placeholders'],
                    $updateSet
                );
            }

            DB::statement($fullSql, $data['values']);

            if ($verbose) {
                $done = min(($i + 1) * $chunkSize, $totalRows);
                $pct = round(($done / $totalRows) * 100);
                $this->info(sprintf(
                    '  [%s] chunk %d/%d — %d/%d rows (%d%%)',
                    $table,
                    $i + 1,
                    count($chunks),
                    $done,
                    $totalRows,
                    $pct
                ));
            }
        }
    }

    /**
     * Fetch existing row or insert and return the row.
     *
     * @param  array  $data  Associative
     * @param  array  $options  ['matchColumns' => [], 'select' => '*']
     */
    protected function firstOrInsert(
        string $table,
        array $data,
        array $options
    ): object {
        $matchColumns = $options['matchColumns'];
        $select = $options['select'] ?? '*';
        $isPg = $this->isPostgres();

        $allColumns = array_keys($data);
        $allValues = array_values($data);

        $whereClause = implode(' AND ', array_map(function ($col) {
            return sprintf('%s = ?', $this->q($col));
        }, $matchColumns));

        $insertCols = implode(', ', array_map([$this, 'q'], $allColumns));
        $insertVals = implode(', ', array_fill(0, count($allColumns), '?'));

        if ($isPg) {
            $sql = "
                WITH existing AS (
                    SELECT {$select}
                    FROM   {$this->q($table)}
                    WHERE  {$whereClause}
                    LIMIT  1
                ),
                inserted AS (
                    INSERT INTO {$this->q($table)} ({$insertCols})
                    SELECT {$insertVals}
                    WHERE  NOT EXISTS (SELECT 1 FROM existing)
                    RETURNING {$select}
                )
                SELECT * FROM existing
                UNION ALL
                SELECT * FROM inserted
            ";
        } else {
            $sql = "
                WITH existing AS (
                    SELECT {$select}
                    FROM   {$this->q($table)}
                    WHERE  {$whereClause}
                    LIMIT  1
                )
                SELECT * FROM existing
            ";

            $bindings = [];
            foreach ($matchColumns as $col) {
                $bindings[] = $data[$col];
            }

            $rows = DB::select($sql, $bindings);

            if (! empty($rows)) {
                return $rows[0];
            }

            $insertSql = sprintf(
                'INSERT INTO %s (%s) VALUES (%s)',
                $this->q($table),
                $insertCols,
                $insertVals
            );

            DB::statement($insertSql, $allValues);

            return $this->selectGetFirst($table, array_intersect_key($data, array_flip($matchColumns)), $select);
        }

        $bindings = [];
        foreach ($matchColumns as $col) {
            $bindings[] = $data[$col];
        }
        foreach ($allValues as $val) {
            $bindings[] = $val;
        }

        $rows = DB::select($sql, $bindings);

        if (empty($rows)) {
            throw new \Exception(sprintf('[MigrationMethods.firstOrInsert] No row returned from "%s".', $table));
        }

        return $rows[0];
    }

    /**
     * firstOrInsert but returns only the ID.
     */
    protected function firstOrInsertGetId(
        string $table,
        array $data,
        array $options
    ): int {
        $matchColumns = $options['matchColumns'];
        $returning = $options['returning'] ?? 'id';

        $row = $this->firstOrInsert($table, $data, [
            'matchColumns' => $matchColumns,
            'select' => $returning,
        ]);

        return (int) $row->{$returning};
    }

    /**
     * Simple DELETE with object-based conditions.
     */
    protected function deleteWhere(
        string $table,
        array $conditions
    ): void {
        $keys = array_keys($conditions);
        $values = array_values($conditions);
        $where = implode(' AND ', array_map(function ($key) {
            return sprintf('%s = ?', $this->q($key));
        }, $keys));

        $sql = sprintf('DELETE FROM %s WHERE %s', $this->q($table), $where);
        DB::statement($sql, $values);
    }

    // --- Private Helpers ---

    private function isPostgres(): bool
    {
        return DB::connection()->getDriverName() === 'pgsql';
    }

    private function isSqlite(): bool
    {
        return DB::connection()->getDriverName() === 'sqlite';
    }

    private function q(string $identifier): string
    {
        return DB::connection()->getQueryGrammar()->wrap($identifier);
    }

    private function buildBulkPlaceholders(array $rows, array $columns): array
    {
        $values = [];
        $rowFragments = [];
        $colCount = count($columns);

        foreach ($rows as $row) {
            $placeholders = array_fill(0, $colCount, '?');

            foreach ($columns as $col) {
                $val = $row[$col] ?? null;
                if (is_array($val)) {
                    $val = json_encode($val);
                }
                $values[] = $val;
            }

            $rowFragments[] = '('.implode(', ', $placeholders).')';
        }

        return [
            'placeholders' => implode(', ', $rowFragments),
            'values' => $values,
        ];
    }

    private function buildConditionsFromRow(array $columns, array $row, array $conflictColumns): array
    {
        $conditions = [];
        foreach ($conflictColumns as $col) {
            $idx = array_search($col, $columns);
            if ($idx !== false) {
                $conditions[$col] = $row[$idx];
            }
        }

        return $conditions;
    }

    private function selectGetFirstValue(string $table, array $conditions, string $field): int
    {
        $result = $this->selectGetFirst($table, $conditions, $this->q($field));

        if (! $result) {
            throw new \Exception(sprintf('[MigrationMethods] Row not found in "%s" for given conditions', $table));
        }

        return (int) $result->{$field};
    }

    private function info(string $message): void
    {
        if (method_exists($this, 'getOutput') && $this->getOutput()) {
            $this->getOutput()->writeln($message);
        } else {
            echo $message.PHP_EOL;
        }
    }
}
