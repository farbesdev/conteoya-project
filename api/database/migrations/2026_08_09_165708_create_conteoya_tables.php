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
        // 1. DOMINIO GEOGRÁFICO
        Schema::create('departments', function (Blueprint $table) {
            $table->string('code', 5)->primary();
            $table->string('name', 100);
            $table->timestamps();
        });

        Schema::create('provinces', function (Blueprint $table) {
            $table->string('code', 5)->primary();
            $table->string('department_code', 5);
            $table->foreign('department_code')->references('code')->on('departments')->onDelete('restrict');
            $table->string('name', 100);
            $table->timestamps();
        });

        Schema::create('districts', function (Blueprint $table) {
            $table->string('code', 6)->primary();
            $table->string('province_code', 5);
            $table->foreign('province_code')->references('code')->on('provinces')->onDelete('restrict');
            $table->string('department_code', 5);
            $table->foreign('department_code')->references('code')->on('departments')->onDelete('restrict');
            $table->string('name', 100);
            $table->timestamps();
        });

        Schema::create('electoral_locations', function (Blueprint $table) {
            $table->id();
            $table->string('district_code', 6);
            $table->foreign('district_code')->references('code')->on('districts')->onDelete('restrict');
            $table->string('name', 255);
            $table->string('address', 255)->nullable();
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->timestamps();
        });

        Schema::create('polling_stations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('electoral_location_id')->constrained('electoral_locations')->onDelete('restrict');
            $table->string('code', 10)->unique();
            $table->integer('registered_voters')->default(0);
            $table->string('status', 20)->default('ACTIVE');
            $table->timestamps();
        });

        // 2. DOMINIO CATÁLOGO ELECTORAL & CANDIDATURAS
        Schema::create('elections', function (Blueprint $table) {
            $table->id();
            $table->string('code', 50)->unique();
            $table->string('name', 255);
            $table->date('date');
            $table->string('status', 20)->default('PLANNED');
            $table->timestamps();
        });

        Schema::create('electoral_levels', function (Blueprint $table) {
            $table->id();
            $table->foreignId('election_id')->constrained('elections')->onDelete('cascade');
            $table->string('code', 50);
            $table->string('name', 100);
            $table->boolean('has_preferential_vote')->default(false);
            $table->timestamps();
            $table->unique(['election_id', 'code']);
        });

        Schema::create('political_organizations', function (Blueprint $table) {
            $table->id();
            $table->integer('jee_id')->nullable()->unique();
            $table->string('name', 255);
            $table->string('short_name', 50)->nullable();
            $table->string('org_type', 50)->nullable();
            $table->text('logo_url')->nullable();
            $table->text('local_logo_url')->nullable();
            $table->timestamps();
        });

        Schema::create('electoral_lists', function (Blueprint $table) {
            $table->id();
            $table->integer('jee_solicitud_id')->nullable()->unique();
            $table->foreignId('political_organization_id')->constrained('political_organizations')->onDelete('restrict');
            $table->foreignId('electoral_level_id')->constrained('electoral_levels')->onDelete('restrict');
            $table->string('department_code', 5)->nullable();
            $table->foreign('department_code')->references('code')->on('departments')->onDelete('restrict');
            $table->string('province_code', 5)->nullable();
            $table->foreign('province_code')->references('code')->on('provinces')->onDelete('restrict');
            $table->string('district_code', 6)->nullable();
            $table->foreign('district_code')->references('code')->on('districts')->onDelete('restrict');
            $table->string('status', 50)->default('INSCRITO');
            $table->timestamps();
        });

        Schema::create('candidates', function (Blueprint $table) {
            $table->id();
            $table->integer('jee_candidate_id')->nullable()->unique();
            $table->string('id_hoja_vida', 100)->nullable();
            $table->string('document_number', 20)->nullable();
            $table->string('full_name', 255);
            $table->text('photo_url')->nullable();
            $table->text('local_photo_url')->nullable();
            $table->timestamps();
        });

        Schema::create('candidacies', function (Blueprint $table) {
            $table->id();
            $table->foreignId('electoral_list_id')->constrained('electoral_lists')->onDelete('cascade');
            $table->foreignId('candidate_id')->constrained('candidates')->onDelete('cascade');
            $table->string('position', 100);
            $table->integer('list_number')->default(0);
            $table->string('status', 50)->default('INSCRITO');
            $table->timestamps();
            $table->unique(['electoral_list_id', 'candidate_id']);
        });

        // 3. DOMINIO USUARIOS, PERSONEROS Y DISPOSITIVOS
        Schema::create('personeros', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade')->unique();
            $table->string('document_number', 20)->unique();
            $table->string('phone_number', 20)->nullable();
            $table->timestamps();
        });

        Schema::create('devices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('personero_id')->constrained('personeros')->onDelete('cascade');
            $table->string('device_uuid', 100)->unique();
            $table->string('device_model', 100)->nullable();
            $table->string('os_version', 50)->nullable();
            $table->string('app_version', 50)->nullable();
            $table->timestamp('last_active_at')->nullable();
            $table->timestamps();
        });

        Schema::create('personero_polling_station', function (Blueprint $table) {
            $table->id();
            $table->foreignId('personero_id')->constrained('personeros')->onDelete('cascade');
            $table->foreignId('polling_station_id')->constrained('polling_stations')->onDelete('cascade');
            $table->timestamp('assigned_at')->useCurrent();
            $table->unique(['personero_id', 'polling_station_id']);
        });

        // 4. DOMINIO INGESTA, ACTAS Y RESULTADOS (FASE 1)
        Schema::create('acts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('election_id')->constrained('elections')->onDelete('restrict');
            $table->foreignId('electoral_level_id')->constrained('electoral_levels')->onDelete('restrict');
            $table->foreignId('polling_station_id')->constrained('polling_stations')->onDelete('restrict');
            $table->string('act_code', 20)->nullable();
            $table->string('status', 30)->default('DRAFT');
            $table->foreignId('captured_by_personero_id')->constrained('personeros')->onDelete('restrict');
            $table->timestamp('captured_at')->useCurrent();
            $table->timestamp('confirmed_at')->nullable();
            $table->timestamps();
            $table->unique(['polling_station_id', 'election_id', 'electoral_level_id']);
        });

        Schema::create('act_totals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('act_id')->unique()->constrained('acts')->onDelete('cascade');
            $table->integer('registered_voters');
            $table->integer('voters_who_voted');
            $table->integer('total_votes');
            $table->integer('blank_votes')->default(0);
            $table->integer('null_votes')->default(0);
            $table->integer('challenged_votes')->default(0);
            $table->boolean('is_valid_total')->default(true);
            $table->timestamps();
        });

        Schema::create('act_results', function (Blueprint $table) {
            $table->id();
            $table->foreignId('act_id')->constrained('acts')->onDelete('cascade');
            $table->foreignId('political_organization_id')->nullable()->constrained('political_organizations')->onDelete('restrict');
            $table->foreignId('electoral_list_id')->nullable()->constrained('electoral_lists')->onDelete('restrict');
            $table->foreignId('candidate_id')->nullable()->constrained('candidates')->onDelete('restrict');
            $table->integer('votes')->default(0);
            $table->string('source', 20)->default('MANUAL');
            $table->decimal('confidence', 5, 4)->nullable();
            $table->timestamps();
        });

        Schema::create('act_evidence', function (Blueprint $table) {
            $table->id();
            $table->foreignId('act_id')->constrained('acts')->onDelete('cascade');
            $table->foreignId('device_id')->nullable()->constrained('devices')->onDelete('set null');
            $table->string('storage_provider', 50)->default('R2');
            $table->text('object_key');
            $table->string('file_mime', 50)->default('image/jpeg');
            $table->bigInteger('file_size_bytes');
            $table->string('sha256_hash', 64);
            $table->integer('width_px')->nullable();
            $table->integer('height_px')->nullable();
            $table->timestamp('captured_at');
            $table->timestamps();
        });

        Schema::create('ocr_ai_extractions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('act_id')->constrained('acts')->onDelete('cascade');
            $table->foreignId('act_evidence_id')->constrained('act_evidence')->onDelete('cascade');
            $table->string('provider_name', 50);
            $table->jsonb('raw_response_json');
            $table->jsonb('extracted_data_json');
            $table->timestamp('processed_at')->useCurrent();
        });

        // 5. DOMINIO OFFLINE, SINCRONIZACIÓN Y AUDITORÍA
        Schema::create('sync_operations', function (Blueprint $table) {
            $table->id();
            $table->uuid('client_operation_id')->unique();
            $table->foreignId('device_id')->constrained('devices')->onDelete('restrict');
            $table->foreignId('personero_id')->constrained('personeros')->onDelete('restrict');
            $table->string('entity_type', 50);
            $table->string('entity_id', 100);
            $table->string('operation', 20);
            $table->jsonb('payload');
            $table->integer('attempts')->default(1);
            $table->string('status', 20)->default('PENDING');
            $table->text('last_error')->nullable();
            $table->timestamp('processed_at')->nullable();
            $table->timestamps();
        });

        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained('users')->onDelete('set null');
            $table->string('action', 100);
            $table->string('entity_type', 50);
            $table->string('entity_id', 100);
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->jsonb('payload')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('audit_logs');
        Schema::dropIfExists('sync_operations');
        Schema::dropIfExists('ocr_ai_extractions');
        Schema::dropIfExists('act_evidence');
        Schema::dropIfExists('act_results');
        Schema::dropIfExists('act_totals');
        Schema::dropIfExists('acts');
        Schema::dropIfExists('personero_polling_station');
        Schema::dropIfExists('devices');
        Schema::dropIfExists('personeros');
        Schema::dropIfExists('candidacies');
        Schema::dropIfExists('candidates');
        Schema::dropIfExists('electoral_lists');
        Schema::dropIfExists('political_organizations');
        Schema::dropIfExists('electoral_levels');
        Schema::dropIfExists('elections');
        Schema::dropIfExists('polling_stations');
        Schema::dropIfExists('electoral_locations');
        Schema::dropIfExists('districts');
        Schema::dropIfExists('provinces');
        Schema::dropIfExists('departments');
    }
};
