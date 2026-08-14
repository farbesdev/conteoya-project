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
        Schema::table('polling_stations', function (Blueprint $table) {
            $table->string('code', 10)->nullable()->change();
            $table->foreignId('electoral_location_id')->nullable()->change();
            $table->string('odpe', 100)->nullable()->after('status');
            $table->string('pdf_file', 255)->nullable()->after('odpe');
            $table->integer('pdf_page')->nullable()->after('pdf_file');
            $table->string('department_name', 100)->nullable()->after('pdf_page');
            $table->string('province_name', 100)->nullable()->after('department_name');
            $table->string('district_name', 100)->nullable()->after('province_name');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('polling_stations', function (Blueprint $table) {
            $table->dropColumn([
                'odpe',
                'pdf_file',
                'pdf_page',
                'department_name',
                'province_name',
                'district_name',
            ]);
        });
    }
};
