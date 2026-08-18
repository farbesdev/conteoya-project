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
        Schema::table('personeros', function (Blueprint $table) {
            $table->foreignId('user_id')->nullable()->change();
            $table->foreignId('election_id')->nullable()->after('user_id')->constrained('elections')->onDelete('set null');
            $table->foreignId('political_organization_id')->nullable()->after('election_id')->constrained('political_organizations')->onDelete('set null');
            $table->string('full_name', 255)->nullable()->after('document_number');
            $table->string('first_name', 100)->nullable()->after('full_name');
            $table->string('email', 150)->nullable()->index()->after('first_name');
            $table->string('personero_type', 50)->nullable()->after('email'); // strCargoEleccion
            $table->integer('id_tipo_personero')->nullable()->after('personero_type');
            $table->string('status', 50)->default('RECONOCIDO')->index()->after('phone_number'); // strEstado
            $table->string('expediente_ext', 50)->nullable()->index()->after('status'); // strCodExpedienteExt
            $table->string('codigo_declara', 50)->nullable()->after('expediente_ext'); // strCodigoDeclara
            $table->integer('jee_personero_declara_id')->nullable()->index()->after('codigo_declara'); // idPersoneroDeclara
            $table->string('political_organization_name', 255)->nullable()->after('jee_personero_declara_id');
            $table->string('jee_name', 100)->nullable()->after('political_organization_name'); // strJuradoElectoral
            $table->integer('jee_id')->nullable()->after('jee_name'); // _idJuradoConsultado
            $table->string('department_name', 100)->nullable()->after('jee_id');
            $table->string('province_name', 100)->nullable()->after('department_name');
            $table->string('district_name', 100)->nullable()->after('province_name');
            $table->string('abogado_responsable', 255)->nullable()->after('district_name');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('personeros', function (Blueprint $table) {
            $table->dropForeign(['election_id']);
            $table->dropForeign(['political_organization_id']);
            $table->dropColumn([
                'election_id',
                'political_organization_id',
                'full_name',
                'first_name',
                'email',
                'personero_type',
                'id_tipo_personero',
                'status',
                'expediente_ext',
                'codigo_declara',
                'jee_personero_declara_id',
                'political_organization_name',
                'jee_name',
                'jee_id',
                'department_name',
                'province_name',
                'district_name',
                'abogado_responsable',
            ]);
        });
    }
};
