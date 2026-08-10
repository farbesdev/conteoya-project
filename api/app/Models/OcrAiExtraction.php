<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OcrAiExtraction extends Model
{
    public $timestamps = false;

    protected $table = 'ocr_ai_extractions';

    protected $fillable = [
        'act_id',
        'act_evidence_id',
        'provider_name',
        'raw_response_json',
        'extracted_data_json',
        'processed_at',
    ];

    protected $casts = [
        'raw_response_json'   => 'array',
        'extracted_data_json' => 'array',
        'processed_at'        => 'datetime',
    ];

    public function act()
    {
        return $this->belongsTo(Act::class, 'act_id');
    }

    public function evidence()
    {
        return $this->belongsTo(ActEvidence::class, 'act_evidence_id');
    }
}
