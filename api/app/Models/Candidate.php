<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Candidate extends Model
{
    protected $fillable = [
        'jee_candidate_id',
        'id_hoja_vida',
        'document_number',
        'full_name',
        'photo_url',
        'local_photo_url'
    ];

    public function candidacies()
    {
        return $this->hasMany(Candidacy::class, 'candidate_id');
    }

    public function cv()
    {
        return $this->hasOne(CandidateCv::class, 'id_hoja_vida', 'id_hoja_vida');
    }
}
