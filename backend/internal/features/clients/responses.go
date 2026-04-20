package clients

import (
	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/bieltris/jimeri/backend/internal/pgconv"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
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
			ResponsibleName:     pgconv.TextPointer(row.ResponsibleName),
			ResponsibleWhatsapp: pgconv.TextPointer(row.ResponsibleWhatsapp),
			Note:                pgconv.TextPointer(row.Note),
			Active:              row.Active,
			CreatedAt:           pgconv.TimeString(row.CreatedAt),
			UpdatedAt:           pgconv.TimeString(row.UpdatedAt),
		},
		BalanceCents: row.BalanceCents,
	}
}

func clientWithBalanceFromDebtRow(row db.ListClientsWithDebtRow) clientWithBalanceResponse {
	return clientWithBalanceResponse{
		Client: clientResponse{
			ID:                  uuidutil.ToString(row.ID),
			Name:                row.Name,
			ResponsibleName:     pgconv.TextPointer(row.ResponsibleName),
			ResponsibleWhatsapp: pgconv.TextPointer(row.ResponsibleWhatsapp),
			Note:                pgconv.TextPointer(row.Note),
			Active:              row.Active,
			CreatedAt:           pgconv.TimeString(row.CreatedAt),
			UpdatedAt:           pgconv.TimeString(row.UpdatedAt),
		},
		BalanceCents: row.BalanceCents,
	}
}

func toClientResponse(client db.Client) clientResponse {
	return clientResponse{
		ID:                  uuidutil.ToString(client.ID),
		Name:                client.Name,
		ResponsibleName:     pgconv.TextPointer(client.ResponsibleName),
		ResponsibleWhatsapp: pgconv.TextPointer(client.ResponsibleWhatsapp),
		Note:                pgconv.TextPointer(client.Note),
		Active:              client.Active,
		CreatedAt:           pgconv.TimeString(client.CreatedAt),
		UpdatedAt:           pgconv.TimeString(client.UpdatedAt),
	}
}
