ALTER TABLE payments
    ADD COLUMN payment_method TEXT NOT NULL DEFAULT 'cash';

ALTER TABLE payments
    ADD CONSTRAINT payments_payment_method_check CHECK (
        payment_method IN (
            'cash',
            'pix',
            'debit_card',
            'credit_card',
            'meal_voucher',
            'bank_transfer',
            'other'
        )
    );
