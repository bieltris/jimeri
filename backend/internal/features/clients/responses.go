package clients

import (
	"time"

	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
	"github.com/jackc/pgx/v5/pgtype"
)

type clientResponse struct {
	ID                  string  `json:"id"`
	Name                string  `json:"name"`
	ResponsibleName     *string `json:"responsibleName"`
	ResponsibleWhatsapp *string `json:"responsibleWhatsapp"`
	Note                *string `json:"note"`
	Active              bool    `json:"active"`
	CreatedAt           string  `json:"createdAt"`
	UpdatedAt           string  `json:"updatedAt"`
}

type clientWithBalanceResponse struct {
	Client       clientResponse `json:"client"`
	BalanceCents int64          `json:"balanceCents"`
}

func clientWithBalanceFromListRow(row db.ListClientsRow) clientWithBalanceResponse {
	return clientWithBalanceResponse{
		Client: clientResponse{
			ID:                  uuidutil.ToString(row.ID),
			Name:                row.Name,
			ResponsibleName:     textPointer(row.ResponsibleName),
			ResponsibleWhatsapp: textPointer(row.ResponsibleWhatsapp),
			Note:                textPointer(row.Note),
			Active:              row.Active,
			CreatedAt:           timeString(row.CreatedAt),
			UpdatedAt:           timeString(row.UpdatedAt),
		},
		BalanceCents: row.BalanceCents,
	}
}

func clientWithBalanceFromDebtRow(row db.ListClientsWithDebtRow) clientWithBalanceResponse {
	return clientWithBalanceResponse{
		Client: clientResponse{
			ID:                  uuidutil.ToString(row.ID),
			Name:                row.Name,
			ResponsibleName:     textPointer(row.ResponsibleName),
			ResponsibleWhatsapp: textPointer(row.ResponsibleWhatsapp),
			Note:                textPointer(row.Note),
			Active:              row.Active,
			CreatedAt:           timeString(row.CreatedAt),
			UpdatedAt:           timeString(row.UpdatedAt),
		},
		BalanceCents: row.BalanceCents,
	}
}

func toClientResponse(client db.Client) clientResponse {
	return clientResponse{
		ID:                  uuidutil.ToString(client.ID),
		Name:                client.Name,
		ResponsibleName:     textPointer(client.ResponsibleName),
		ResponsibleWhatsapp: textPointer(client.ResponsibleWhatsapp),
		Note:                textPointer(client.Note),
		Active:              client.Active,
		CreatedAt:           timeString(client.CreatedAt),
		UpdatedAt:           timeString(client.UpdatedAt),
	}
}

func textPointer(value pgtype.Text) *string {
	if !value.Valid {
		return nil
	}

	return &value.String
}

func timeString(value pgtype.Timestamptz) string {
	if !value.Valid {
		return ""
	}

	return value.Time.Format(time.RFC3339)
}
