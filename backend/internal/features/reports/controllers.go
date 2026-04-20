package reports

import (
	"net/http"
	"time"

	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/bieltris/jimeri/backend/internal/respond"
	"github.com/jackc/pgx/v5/pgtype"
)

func (h *Handler) dashboard(w http.ResponseWriter, r *http.Request) {
	summary, err := h.queries.GetDashboardSummary(r.Context())
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not get dashboard summary")
		return
	}

	start, end := h.dayRange(time.Now())

	ordersTotal, err := h.queries.GetDailyOrdersTotal(r.Context(), db.GetDailyOrdersTotalParams{
		CreatedAt:   pgtype.Timestamptz{Time: start, Valid: true},
		CreatedAt_2: pgtype.Timestamptz{Time: end, Valid: true},
	})
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not get daily orders total")
		return
	}

	paymentsTotal, err := h.queries.GetDailyPaymentsTotal(r.Context(), db.GetDailyPaymentsTotalParams{
		CreatedAt:   pgtype.Timestamptz{Time: start, Valid: true},
		CreatedAt_2: pgtype.Timestamptz{Time: end, Valid: true},
	})
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not get daily payments total")
		return
	}

	respond.JSON(w, http.StatusOK, dashboardResponse{
		OpenBalanceCents:   summary.OpenBalanceCents,
		ClientsWithDebt:    summary.ClientsWithDebt,
		TotalClients:       summary.TotalClients,
		DailyOrdersCents:   ordersTotal,
		DailyPaymentsCents: paymentsTotal,
		ReportDate:         start.Format("2006-01-02"),
		ReportTimezone:     h.location.String(),
	})
}

func (h *Handler) debts(w http.ResponseWriter, r *http.Request) {
	rows, err := h.queries.ListClientsWithDebt(r.Context())
	if err != nil {
		respond.Error(w, http.StatusInternalServerError, "could not list debts")
		return
	}

	respond.JSON(w, http.StatusOK, debtsResponse{
		Clients:           toDebtClientResponses(rows),
		TotalBalanceCents: totalBalance(rows),
	})
}

func (h *Handler) dayRange(now time.Time) (time.Time, time.Time) {
	localNow := now.In(h.location)
	start := time.Date(localNow.Year(), localNow.Month(), localNow.Day(), 0, 0, 0, 0, h.location)

	return start, start.AddDate(0, 0, 1)
}
