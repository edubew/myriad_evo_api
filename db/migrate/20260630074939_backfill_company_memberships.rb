class BackfillCompanyMemberships < ActiveRecord::Migration[7.1]
  def up
    say_with_time 'Backfilling company_memberships from users table...' do
      # Single INSERT ... SELECT — no Ruby-level loop, safe for large tables
      result = execute <<~SQL
        INSERT INTO company_memberships
          (user_id, company_id, role, accepted_at, created_at, updated_at)
        SELECT
          u.id,
          u.company_id,
          u.role,
          u.created_at,
          NOW(),
          NOW()
        FROM users u
        WHERE u.company_id IS NOT NULL
        ON CONFLICT (user_id, company_id) DO NOTHING
      SQL

      say "Inserted #{result.cmd_tuples} membership rows"
    end

    # Safety check — blow up loudly if any user is still missing a membership
    missing_count = execute(<<~SQL).values.flatten.first.to_i
      SELECT COUNT(*) FROM users u
      WHERE u.company_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM company_memberships cm
          WHERE cm.user_id = u.id AND cm.company_id = u.company_id
        )
    SQL

    if missing_count > 0
      raise "Backfill incomplete: #{missing_count} users still missing a company_membership row"
    end

    say "All users accounted for — backfill complete"
  end

  def down
    # On rollback, remove ALL membership rows (the source of truth
    # is still the users.role column until Migration 1 is also rolled back)
    execute "DELETE FROM company_memberships"
    say "Cleared all company_membership rows"
  end
end