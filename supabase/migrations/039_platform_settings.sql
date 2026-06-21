-- Admin-configurable platform settings (key/value). Seeds the marketplace
-- commission rate (0–1). create-checkout reads this for marketplace clients.
CREATE TABLE IF NOT EXISTS platform_settings (
  key        text PRIMARY KEY,
  value      text NOT NULL,
  updated_at timestamptz DEFAULT now()
);

INSERT INTO platform_settings (key, value) VALUES
  ('marketplace_commission_rate', '0.10')
ON CONFLICT (key) DO NOTHING;

ALTER TABLE platform_settings ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can READ settings (checkout/coach need the rate).
DROP POLICY IF EXISTS "read platform settings" ON platform_settings;
CREATE POLICY "read platform settings" ON platform_settings
  FOR SELECT TO authenticated USING (true);

-- Only admins can change them.
DROP POLICY IF EXISTS "admin writes platform settings" ON platform_settings;
CREATE POLICY "admin writes platform settings" ON platform_settings
  FOR ALL TO authenticated
  USING      (EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'));
