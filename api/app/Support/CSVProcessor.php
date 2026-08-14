<?php

declare(strict_types=1);

namespace App\Support;

use SplFileObject;
use Generator;
use Illuminate\Support\LazyCollection;

class CSVProcessor
{
    private string $filePath;
    private string $delimiter = ',';
    private string $enclosure = '"';
    private string $escape = '\\';
    private bool $hasHeaders = true;
    private array $headers = [];

    public static function file(string $filePath): self
    {
        $instance = new self();
        $instance->filePath = $filePath;
        return $instance;
    }

    public function withDelimiter(string $delimiter): self
    {
        $this->delimiter = $delimiter;
        return $this;
    }

    public function withEnclosure(string $enclosure): self
    {
        $this->enclosure = $enclosure;
        return $this;
    }

    public function withEscape(string $escape): self
    {
        $this->escape = $escape;
        return $this;
    }

    public function withoutHeaders(): self
    {
        $this->hasHeaders = false;
        return $this;
    }

    public function withHeaders(array $headers): self
    {
        $this->headers = $headers;
        return $this;
    }

    /**
     * Devuelve las filas una a una como Generator
     *
     * @return Generator<int, array<string|int, mixed>>
     */
    public function getRows(): Generator
    {
        $file = new SplFileObject($this->filePath, 'r');
        $file->setFlags(SplFileObject::READ_CSV | SplFileObject::SKIP_EMPTY | SplFileObject::DROP_NEW_LINE);
        $file->setCsvControl($this->delimiter, $this->enclosure, $this->escape);

        $headers = [];
        $index = 0;

        while (!$file->eof()) {
            $row = $file->fgetcsv();
            if ($row === false || $row === null || $row === [null] || $row === []) {
                continue;
            }

            if ($this->hasHeaders && $index === 0) {
                $headers = array_map(function($h) {
                    $cleaned = str_replace("\xEF\xBB\xBF", '', (string) $h);
                    return strtolower(trim($cleaned));
                }, $row);
                $index++;
                continue;
            }

            if ($this->hasHeaders) {
                $diff = count($headers) - count($row);
                if ($diff > 0) {
                    $row = array_merge($row, array_fill(0, $diff, ''));
                } elseif ($diff < 0) {
                    $row = array_slice($row, 0, count($headers));
                }
                yield array_combine($headers, $row);
            } else {
                yield $row;
            }
            $index++;
        }
    }

    /**
     * Devuelve las filas encapsuladas en un LazyCollection de Laravel
     *
     * @return LazyCollection<int, array<string|int, mixed>>
     */
    public function getRowsAsLazyCollection(): LazyCollection
    {
        return LazyCollection::make(fn() => $this->getRows());
    }

    /**
     * Escribe un conjunto masivo de filas utilizando generators/iterables
     *
     * @param iterable $rows
     * @return void
     */
    public function writeRows(iterable $rows): void
    {
        $dir = dirname($this->filePath);
        if (!is_dir($dir)) {
            mkdir($dir, 0755, true);
        }

        $file = new SplFileObject($this->filePath, 'w');

        if ($this->hasHeaders && !empty($this->headers)) {
            $file->fputcsv($this->headers, $this->delimiter, $this->enclosure, $this->escape);
        }

        foreach ($rows as $row) {
            $file->fputcsv((array) $row, $this->delimiter, $this->enclosure, $this->escape);
        }
    }
}
