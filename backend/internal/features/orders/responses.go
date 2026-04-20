package orders

import (
	"github.com/bieltris/jimeri/backend/internal/db"
	"github.com/bieltris/jimeri/backend/internal/pgconv"
	"github.com/bieltris/jimeri/backend/internal/uuidutil"
	"github.com/jackc/pgx/v5/pgtype"
)

type orderResponse struct {
	ID           string  `json:"id"`
	ClientID     string  `json:"clientId"`
	CreatedBy    string  `json:"createdBy"`
	Note         *string `json:"note"`
	CancelledAt  string  `json:"cancelledAt,omitempty"`
	CancelledBy  *string `json:"cancelledBy,omitempty"`
	CancelReason *string `json:"cancelReason,omitempty"`
	CreatedAt    string  `json:"createdAt"`
}

type orderItemResponse struct {
	ID             string `json:"id"`
	OrderID        string `json:"orderId"`
	ProductID      string `json:"productId"`
	ProductName    string `json:"productName"`
	Quantity       int32  `json:"quantity"`
	UnitPriceCents int64  `json:"unitPriceCents"`
	SubtotalCents  int64  `json:"subtotalCents"`
	CreatedAt      string `json:"createdAt"`
}

type orderWithItemsResponse struct {
	Order      orderResponse       `json:"order"`
	Items      []orderItemResponse `json:"items"`
	TotalCents int64               `json:"totalCents"`
}

type orderSummaryResponse struct {
	Order      orderResponse `json:"order"`
	TotalCents int64         `json:"totalCents"`
}

func toOrderWithItemsResponse(order db.Order, items []db.OrderItem) orderWithItemsResponse {
	itemResponses := make([]orderItemResponse, 0, len(items))
	var totalCents int64

	for _, item := range items {
		response := toOrderItemResponse(item)
		totalCents += response.SubtotalCents
		itemResponses = append(itemResponses, response)
	}

	return orderWithItemsResponse{
		Order:      toOrderResponse(order),
		Items:      itemResponses,
		TotalCents: totalCents,
	}
}

func toOrderSummaryResponses(rows []db.ListClientOrdersRow) []orderSummaryResponse {
	response := make([]orderSummaryResponse, 0, len(rows))
	for _, row := range rows {
		response = append(response, orderSummaryResponse{
			Order: orderResponse{
				ID:           uuidutil.ToString(row.ID),
				ClientID:     uuidutil.ToString(row.ClientID),
				CreatedBy:    uuidutil.ToString(row.CreatedBy),
				Note:         pgconv.TextPointer(row.Note),
				CancelledAt:  pgconv.TimeString(row.CancelledAt),
				CancelledBy:  uuidPointer(row.CancelledBy),
				CancelReason: pgconv.TextPointer(row.CancelReason),
				CreatedAt:    pgconv.TimeString(row.CreatedAt),
			},
			TotalCents: row.TotalCents,
		})
	}

	return response
}

func toOrderResponse(order db.Order) orderResponse {
	return orderResponse{
		ID:           uuidutil.ToString(order.ID),
		ClientID:     uuidutil.ToString(order.ClientID),
		CreatedBy:    uuidutil.ToString(order.CreatedBy),
		Note:         pgconv.TextPointer(order.Note),
		CancelledAt:  pgconv.TimeString(order.CancelledAt),
		CancelledBy:  uuidPointer(order.CancelledBy),
		CancelReason: pgconv.TextPointer(order.CancelReason),
		CreatedAt:    pgconv.TimeString(order.CreatedAt),
	}
}

func toOrderItemResponse(item db.OrderItem) orderItemResponse {
	subtotalCents := item.UnitPriceCents * int64(item.Quantity)

	return orderItemResponse{
		ID:             uuidutil.ToString(item.ID),
		OrderID:        uuidutil.ToString(item.OrderID),
		ProductID:      uuidutil.ToString(item.ProductID),
		ProductName:    item.ProductName,
		Quantity:       item.Quantity,
		UnitPriceCents: item.UnitPriceCents,
		SubtotalCents:  subtotalCents,
		CreatedAt:      pgconv.TimeString(item.CreatedAt),
	}
}

func uuidPointer(value pgtype.UUID) *string {
	if !value.Valid {
		return nil
	}

	id := uuidutil.ToString(value)
	return &id
}
