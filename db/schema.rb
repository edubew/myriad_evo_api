# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_04_01_234630) do
  create_schema "auth"
  create_schema "extensions"
  create_schema "graphql"
  create_schema "graphql_public"
  create_schema "pgbouncer"
  create_schema "realtime"
  create_schema "storage"
  create_schema "vault"

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_graphql"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "supabase_vault"
  enable_extension "uuid-ossp"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "allocation_settings", force: :cascade do |t|
    t.decimal "salary_pct", precision: 5, scale: 2, default: "40.0"
    t.decimal "ops_pct", precision: 5, scale: 2, default: "25.0"
    t.decimal "profit_pct", precision: 5, scale: 2, default: "35.0"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["company_id"], name: "index_allocation_settings_on_company_id"
    t.index ["user_id"], name: "index_allocation_settings_on_user_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "company_name", null: false
    t.string "industry"
    t.string "website"
    t.string "email"
    t.string "phone"
    t.string "status", default: "active"
    t.text "notes"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "internal"
    t.bigint "company_id"
    t.index ["company_id"], name: "index_clients_on_company_id"
    t.index ["company_name"], name: "index_clients_on_company_name"
    t.index ["status"], name: "index_clients_on_status"
    t.index ["user_id"], name: "index_clients_on_user_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "plan", default: "starter"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_companies_on_slug", unique: true
  end

  create_table "contacts", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.string "phone"
    t.string "role"
    t.boolean "is_primary", default: false
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["client_id"], name: "index_contacts_on_client_id"
    t.index ["company_id"], name: "index_contacts_on_company_id"
  end

  create_table "daily_todos", force: :cascade do |t|
    t.string "text", null: false
    t.boolean "done", default: false
    t.date "date", null: false
    t.integer "position", default: 0
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["company_id"], name: "index_daily_todos_on_company_id"
    t.index ["user_id", "date"], name: "index_daily_todos_on_user_id_and_date"
    t.index ["user_id"], name: "index_daily_todos_on_user_id"
  end

  create_table "deals", force: :cascade do |t|
    t.string "title", null: false
    t.decimal "value", precision: 12, scale: 2, default: "0.0"
    t.integer "probability", default: 0
    t.date "expected_close"
    t.string "status", default: "lead"
    t.text "notes"
    t.integer "position", default: 0
    t.bigint "user_id", null: false
    t.bigint "client_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["client_id"], name: "index_deals_on_client_id"
    t.index ["company_id"], name: "index_deals_on_company_id"
    t.index ["status", "position"], name: "index_deals_on_status_and_position"
    t.index ["status"], name: "index_deals_on_status"
    t.index ["user_id"], name: "index_deals_on_user_id"
  end

  create_table "documents", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "file_url"
    t.string "file_name"
    t.integer "file_size"
    t.string "file_type"
    t.string "category", default: "general"
    t.bigint "user_id", null: false
    t.bigint "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["category"], name: "index_documents_on_category"
    t.index ["company_id"], name: "index_documents_on_company_id"
    t.index ["project_id"], name: "index_documents_on_project_id"
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.boolean "all_day", default: false
    t.string "location"
    t.string "event_type", default: "meeting"
    t.string "color"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source", default: "manual"
    t.integer "source_id"
    t.bigint "company_id"
    t.index ["company_id"], name: "index_events_on_company_id"
    t.index ["event_type"], name: "index_events_on_event_type"
    t.index ["source", "source_id"], name: "index_events_on_source_and_source_id"
    t.index ["start_time"], name: "index_events_on_start_time"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "goals", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.date "target_date"
    t.integer "progress", default: 0
    t.string "status", default: "active"
    t.string "quarter"
    t.integer "year"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["company_id"], name: "index_goals_on_company_id"
    t.index ["user_id"], name: "index_goals_on_user_id"
    t.index ["year", "quarter"], name: "index_goals_on_year_and_quarter"
  end

  create_table "invoices", force: :cascade do |t|
    t.string "invoice_number", null: false
    t.string "title", null: false
    t.decimal "amount", precision: 12, scale: 2
    t.decimal "tax_rate", precision: 5, scale: 2, default: "0.0"
    t.decimal "tax_amount", precision: 12, scale: 2, default: "0.0"
    t.decimal "total_amount", precision: 12, scale: 2
    t.string "status", default: "draft"
    t.date "issued_date"
    t.date "due_date"
    t.date "paid_date"
    t.text "notes"
    t.bigint "client_id"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["client_id"], name: "index_invoices_on_client_id"
    t.index ["company_id"], name: "index_invoices_on_company_id"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number", unique: true
    t.index ["status"], name: "index_invoices_on_status"
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti"
    t.datetime "exp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
  end

  create_table "leads", force: :cascade do |t|
    t.string "company_name", null: false
    t.string "contact_name"
    t.string "email"
    t.string "phone"
    t.string "source", default: "other"
    t.string "status", default: "new"
    t.text "notes"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["company_id"], name: "index_leads_on_company_id"
    t.index ["source"], name: "index_leads_on_source"
    t.index ["status"], name: "index_leads_on_status"
    t.index ["user_id"], name: "index_leads_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "status", default: "active"
    t.string "color", default: "#6C63FF"
    t.date "start_date"
    t.date "end_date"
    t.bigint "user_id", null: false
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["client_id"], name: "index_projects_on_client_id"
    t.index ["company_id"], name: "index_projects_on_company_id"
    t.index ["status"], name: "index_projects_on_status"
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "revenue_entries", force: :cascade do |t|
    t.string "title", null: false
    t.decimal "amount", precision: 12, scale: 2
    t.string "source", default: "manual"
    t.integer "source_id"
    t.string "status", default: "pending"
    t.date "date"
    t.text "notes"
    t.decimal "salary_pct", precision: 5, scale: 2
    t.decimal "ops_pct", precision: 5, scale: 2
    t.decimal "profit_pct", precision: 5, scale: 2
    t.decimal "salary_amount", precision: 12, scale: 2
    t.decimal "ops_amount", precision: 12, scale: 2
    t.decimal "profit_amount", precision: 12, scale: 2
    t.bigint "user_id", null: false
    t.bigint "deal_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["company_id"], name: "index_revenue_entries_on_company_id"
    t.index ["deal_id"], name: "index_revenue_entries_on_deal_id"
    t.index ["status"], name: "index_revenue_entries_on_status"
    t.index ["user_id", "date"], name: "index_revenue_entries_on_user_id_and_date"
    t.index ["user_id"], name: "index_revenue_entries_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "status", default: "backlog"
    t.string "priority", default: "medium"
    t.integer "position", default: 0
    t.date "due_date"
    t.bigint "user_id", null: false
    t.bigint "project_id", null: false
    t.bigint "assignee_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["assignee_id"], name: "index_tasks_on_assignee_id"
    t.index ["company_id"], name: "index_tasks_on_company_id"
    t.index ["project_id", "position"], name: "index_tasks_on_project_id_and_position"
    t.index ["project_id", "status"], name: "index_tasks_on_project_id_and_status"
    t.index ["project_id"], name: "index_tasks_on_project_id"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "team_members", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.string "phone"
    t.string "role"
    t.string "department"
    t.text "bio"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar_url"
    t.bigint "company_id"
    t.index ["company_id"], name: "index_team_members_on_company_id"
    t.index ["user_id"], name: "index_team_members_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name", default: "", null: false
    t.string "last_name", default: "", null: false
    t.string "role", default: "member", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "jti", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar_url"
    t.bigint "company_id"
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "allocation_settings", "companies"
  add_foreign_key "allocation_settings", "users"
  add_foreign_key "clients", "companies"
  add_foreign_key "clients", "users"
  add_foreign_key "contacts", "clients"
  add_foreign_key "contacts", "companies"
  add_foreign_key "daily_todos", "companies"
  add_foreign_key "daily_todos", "users"
  add_foreign_key "deals", "clients"
  add_foreign_key "deals", "companies"
  add_foreign_key "deals", "users"
  add_foreign_key "documents", "companies"
  add_foreign_key "documents", "projects"
  add_foreign_key "documents", "users"
  add_foreign_key "events", "companies"
  add_foreign_key "events", "users"
  add_foreign_key "goals", "companies"
  add_foreign_key "goals", "users"
  add_foreign_key "invoices", "clients"
  add_foreign_key "invoices", "companies"
  add_foreign_key "invoices", "users"
  add_foreign_key "leads", "companies"
  add_foreign_key "leads", "users"
  add_foreign_key "projects", "clients"
  add_foreign_key "projects", "companies"
  add_foreign_key "projects", "users"
  add_foreign_key "revenue_entries", "companies"
  add_foreign_key "revenue_entries", "deals"
  add_foreign_key "revenue_entries", "users"
  add_foreign_key "tasks", "companies"
  add_foreign_key "tasks", "projects"
  add_foreign_key "tasks", "users"
  add_foreign_key "tasks", "users", column: "assignee_id"
  add_foreign_key "team_members", "companies"
  add_foreign_key "team_members", "users"
  add_foreign_key "users", "companies"
end
