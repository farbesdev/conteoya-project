<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CandidateCv extends Model
{
    protected $table = 'candidate_cvs';
    protected $primaryKey = 'id_hoja_vida';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'id_hoja_vida',
        'candidate_id',
        'general_data',
        'academic_data',
        'work_experience',
        'political_trajectory',
        'sworn_declaration',
        'penal_sentences',
        'additional_info'
    ];

    protected $casts = [
        'general_data'         => 'array',
        'academic_data'        => 'array',
        'work_experience'      => 'array',
        'political_trajectory' => 'array',
        'sworn_declaration'    => 'array',
        'penal_sentences'      => 'array',
        'additional_info'      => 'array',
    ];

    public function candidate()
    {
        return $this->belongsTo(Candidate::class, 'candidate_id');
    }
}
