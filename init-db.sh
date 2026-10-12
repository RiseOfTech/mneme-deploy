#!/bin/sh
# Runs once, on the first start of an empty postgres volume: one database and one
# owning role per service, so mneme-core and mneme-auth cannot touch each other's data.
set -eu

psql -v ON_ERROR_STOP=1 --username postgres <<-SQL
	CREATE ROLE mneme LOGIN PASSWORD '${CORE_DB_PASSWORD}';
	CREATE DATABASE mneme OWNER mneme;
	CREATE ROLE mneme_auth LOGIN PASSWORD '${AUTH_DB_PASSWORD}';
	CREATE DATABASE mneme_auth OWNER mneme_auth;
SQL
