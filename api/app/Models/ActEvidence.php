<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ActEvidence extends Model
{
    protected $table = 'act_evidence';

    protected $fillable = [
        'act_id',
        'device_id',
        'storage_provider',
        'object_key',
        'file_mime',
        'file_size_bytes',
        'sha256_hash',
        'width_px',
        'height_px',
        'captured_at'
    ];

    public function act()
    {
        return $this->belongsTo(Act::class, 'act_id');
    }

    public function device()
    {
        return $this->belongsTo(Device::class, 'device_id');
    }
}
