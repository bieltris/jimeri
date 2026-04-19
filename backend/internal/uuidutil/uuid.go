package uuidutil

import (
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

func FromString(value string) (pgtype.UUID, error) {
	parsed, err := uuid.Parse(value)
	if err != nil {
		return pgtype.UUID{}, err
	}

	return pgtype.UUID{Bytes: parsed, Valid: true}, nil
}

func ToString(value pgtype.UUID) string {
	if !value.Valid {
		return ""
	}

	return uuid.UUID(value.Bytes).String()
}
