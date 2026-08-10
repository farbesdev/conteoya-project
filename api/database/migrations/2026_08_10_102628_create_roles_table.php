<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Crea la tabla de roles del sistema ConteoYA.
     * Los roles predefinidos son: ADMIN, DIRECTOR y PERSONERO.
     * Se usa una tabla independiente para mantener integridad referencial
     * y permitir extensibilidad futura sin cambios de esquema.
     */
    public function up(): void
    {
        Schema::create('roles', function (Blueprint $table) {
            $table->id();
            $table->string('name', 50)->unique(); // ADMIN | DIRECTOR | PERSONERO
            $table->string('display_name', 100)->nullable();
            $table->text('description')->nullable();
            $table->timestamps();
        });

        // Agregar FK role_id a users una vez que roles exista
        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('role_id')
                  ->nullable()
                  ->after('role')
                  ->constrained('roles')
                  ->onDelete('restrict');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['role_id']);
            $table->dropColumn('role_id');
        });
        Schema::dropIfExists('roles');
    }
};
