<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('candidate_cvs', function (Blueprint $table) {
            $table->string('id_hoja_vida', 100)->primary();
            $table->foreignId('candidate_id')->nullable()->constrained('candidates')->onDelete('cascade');
            $table->json('general_data')->nullable();
            $table->json('academic_data')->nullable();
            $table->json('work_experience')->nullable();
            $table->json('political_trajectory')->nullable();
            $table->json('sworn_declaration')->nullable();
            $table->json('penal_sentences')->nullable();
            $table->json('additional_info')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('candidate_cvs');
    }
};
