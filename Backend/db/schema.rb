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

ActiveRecord::Schema[8.1].define(version: 2026_10_19_170000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
  end

  create_table "carts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_carts_on_user_id", unique: true
  end

  create_table "comment_reactions", force: :cascade do |t|
    t.bigint "comment_id", null: false
    t.bigint "user_id", null: false
    t.string "kind", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_id", "user_id"], name: "index_comment_reactions_on_comment_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_comment_reactions_on_user_id"
    t.check_constraint "kind::text = ANY (ARRAY['like'::character varying::text, 'dislike'::character varying::text])", name: "comment_reactions_kind_allowed"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "user_id", null: false
    t.bigint "parent_id"
    t.text "body", null: false
    t.integer "likes_count", default: 0, null: false
    t.integer "dislikes_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_comments_on_parent_id", unique: true
    t.index ["product_id", "created_at"], name: "index_comments_on_product_top_level", where: "(parent_id IS NULL)"
    t.index ["user_id"], name: "index_comments_on_user_id"
    t.check_constraint "char_length(body) >= 1 AND char_length(body) <= 2000", name: "comments_body_length"
    t.check_constraint "likes_count >= 0 AND dislikes_count >= 0", name: "comments_reaction_counts_nonnegative"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.check_constraint "quantity > 0", name: "order_items_quantity_positive"
    t.check_constraint "unit_price >= 0::numeric", name: "order_items_unit_price_nonnegative"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "total", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.check_constraint "total >= 0::numeric", name: "orders_total_nonnegative"
  end

  create_table "product_metadata", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "rating_sum", default: 0, null: false
    t.bigint "rating_count", default: 0, null: false
    t.bigint "comment_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_metadata_on_product_id", unique: true
    t.check_constraint "rating_sum >= 0 AND rating_count >= 0 AND comment_count >= 0", name: "product_metadata_counters_nonnegative"
  end

  create_table "product_purchases", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "product_id", null: false
    t.integer "rating", limit: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "rating_comment_id"
    t.index ["product_id"], name: "index_product_purchases_on_product_id"
    t.index ["rating_comment_id"], name: "index_product_purchases_on_rating_comment_id"
    t.index ["user_id", "product_id"], name: "index_product_purchases_on_user_id_and_product_id", unique: true
    t.check_constraint "rating IS NULL OR rating >= 1 AND rating <= 5", name: "product_purchases_rating_range"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", limit: 120, null: false
    t.text "description", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "stock", null: false
    t.string "sku", limit: 50
    t.string "category", limit: 40, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "seller_id"
    t.index ["seller_id"], name: "index_products_on_seller_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest"
    t.string "role", default: "buyer", null: false
    t.string "session_token"
    t.string "email_verification_token"
    t.datetime "email_verification_expires_at"
    t.datetime "email_verified_at"
    t.string "google_uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "session_token_expires_at"
    t.string "remember_token"
    t.datetime "remember_token_expires_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["email_verification_token"], name: "index_users_on_email_verification_token", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
    t.index ["remember_token"], name: "index_users_on_remember_token", unique: true
    t.index ["session_token"], name: "index_users_on_session_token", unique: true
    t.check_constraint "role::text = ANY (ARRAY['buyer'::character varying::text, 'seller'::character varying::text, 'admin'::character varying::text])", name: "users_role_allowed"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "carts", "users", on_delete: :cascade
  add_foreign_key "comment_reactions", "comments", on_delete: :cascade
  add_foreign_key "comment_reactions", "users", on_delete: :cascade
  add_foreign_key "comments", "comments", column: "parent_id", on_delete: :cascade
  add_foreign_key "comments", "products", on_delete: :cascade
  add_foreign_key "comments", "users", on_delete: :cascade
  add_foreign_key "order_items", "orders", on_delete: :cascade
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "users", on_delete: :cascade
  add_foreign_key "product_metadata", "products"
  add_foreign_key "product_purchases", "comments", column: "rating_comment_id", on_delete: :nullify
  add_foreign_key "product_purchases", "products", on_delete: :cascade
  add_foreign_key "product_purchases", "users", on_delete: :cascade
  add_foreign_key "products", "users", column: "seller_id"
end
