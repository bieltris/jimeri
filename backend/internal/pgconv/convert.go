package pgconv

import (
	"strings"
	"time"
	"unicode"

	"github.com/jackc/pgx/v5/pgtype"
)

func TextFromPointer(value *string) pgtype.Text {
	if value == nil {
		return pgtype.Text{}
	}

	return TextFromString(*value)
}

func TextFromString(value string) pgtype.Text {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return pgtype.Text{}
	}

	return pgtype.Text{String: trimmed, Valid: true}
}

func DigitsTextFromPointer(value *string) pgtype.Text {
	if value == nil {
		return pgtype.Text{}
	}

	var builder strings.Builder
	for _, char := range *value {
		if unicode.IsDigit(char) {
			builder.WriteRune(char)
		}
	}

	return TextFromString(builder.String())
}

func TextPointer(value pgtype.Text) *string {
	if !value.Valid {
		return nil
	}

	return &value.String
}

func TimeString(value pgtype.Timestamptz) string {
	if !value.Valid {
		return ""
	}

	return value.Time.Format(time.RFC3339)
}
