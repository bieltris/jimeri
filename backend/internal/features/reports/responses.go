package reports

import (
	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/bieltris/jimeri/backend/internal/pgconv"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
)

type dashboardResponse struct {
	OpenBalanceCents   int64  `json:"openBalanceCents"`
	ClientsWithDebt    int64  `json:"clientsWithDebt"`
	TotalClients       int64  `json:"totalClients"`
	DailyOrdersCents   int64  `json:"dailyOrdersCents"`
	DailyPaymentsCents int64  `json:"dailyPaymentsCents"`
	ReportDate         string `json:"reportDate"`
	ReportTimezone     string `json:"reportTimezone"`
}

type debtsResponse struct {
	Clients           []debtClientResponse `json:"clients"`
	TotalBalanceCents int64                `json:"totalBalanceCents"`
}

type debtClientResponse struct {
	ClientID            string  `json:"clientId"`
	Name                string  `json:"name"`
	ResponsibleName     *string `json:"responsibleName"`
	ResponsibleWhatsapp *string `json:"responsibleWhatsapp"`
	BalanceCents        int64   `json:"balanceCents"`
}

func toDebtClientResponses(rows []db.ListClientsWithDebtRow) []debtClientResponse {
	response := make([]debtClientResponse, 0, len(rows))
	for _, row := range rows {
		response = append(response, debtClientResponse{
			ClientID:            uuidutil.ToString(row.ID),
			Name:                row.Name,
			ResponsibleName:     pgconv.TextPointer(row.ResponsibleName),
			ResponsibleWhatsapp: pgconv.TextPointer(row.ResponsibleWhatsapp),
			BalanceCents:        row.BalanceCents,
		})
	}

	return response
}

func totalBalance(rows []db.ListClientsWithDebtRow) int64 {
	var total int64
	for _, row := range rows {
		total += row.BalanceCents
	}

	return total
}
