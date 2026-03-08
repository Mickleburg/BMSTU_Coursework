package main

import (
	"context"
	"fmt"
	"log"

	firebase "firebase.google.com/go/v4"
	"github.com/ethereum/go-ethereum/ethclient"
	"google.golang.org/api/option"
)

type TransactionData struct {
	Hash     string `json:"hash"`
	Value    string `json:"value"`
	Cost     string `json:"cost"`
	To       string `json:"to,omitempty"`
	Gas      uint64 `json:"gas"`
	GasPrice string `json:"gasPrice"`
	ChainID  string `json:"chainId"`
}

type BlockData struct {
	Number           uint64            `json:"number"`
	Time             uint64            `json:"time"`
	Difficulty       uint64            `json:"difficulty"`
	Hash             string            `json:"hash"`
	TransactionCount int               `json:"transactionCount"`
	Transactions     []TransactionData `json:"transactions"`
}

func main() {
	infuraProjectID := "282cb10bb1404eb392a4562ad162057a"
	infuraURL := "https://mainnet.infura.io/v3/" + infuraProjectID

	client, err := ethclient.Dial(infuraURL)
	if err != nil {
		log.Fatalf("Failed to connect to Ethereum node: %v", err)
	}
	defer client.Close()

	// Последний блок:
	header, err := client.HeaderByNumber(context.Background(), nil)
	if err != nil {
		log.Fatalf("Failed to get latest block header: %v", err)
	}

	// Берем весь:
	block, err := client.BlockByNumber(context.Background(), header.Number)
	if err != nil {
		log.Fatalf("Failed to retrieve block %d: %v", header.Number, err)
	}

	fmt.Printf("Block Number: %d\n", block.Number().Uint64())
	fmt.Printf("Timestamp: %d\n", block.Time())
	fmt.Printf("Difficulty: %d\n", block.Difficulty().Uint64())
	fmt.Printf("Hash: %s\n", block.Hash().Hex())
	fmt.Printf("Transaction Count: %d\n", len(block.Transactions()))

	var transactions []TransactionData
	for _, tx := range block.Transactions() {
		toAddr := ""
		if tx.To() != nil {
			toAddr = tx.To().Hex()
		}

		transactions = append(transactions, TransactionData{
			Hash:     tx.Hash().Hex(),
			Value:    tx.Value().String(),
			Cost:     tx.Cost().String(),
			To:       toAddr,
			Gas:      tx.Gas(),
			GasPrice: tx.GasPrice().String(),
			ChainID:  tx.ChainId().String(),
		})
	}

	// Печатаем 3 транзакции в консоль!
	for i, tx := range transactions {
		if i >= 3 {
			break
		}
		fmt.Printf("\nTransaction %d:\n", i+1)
		fmt.Printf("  Hash: %s\n", tx.Hash)
		fmt.Printf("  To: %s\n", tx.To)
		fmt.Printf("  Value (wei): %s\n", tx.Value)
		fmt.Printf("  Gas: %d\n", tx.Gas)
		fmt.Printf("  GasPrice (wei): %s\n", tx.GasPrice)
		fmt.Printf("  Cost (wei): %s\n", tx.Cost)
		fmt.Printf("  ChainID: %s\n", tx.ChainID)
	}

	// И в датабэйс
	ctx := context.Background()

	config := &firebase.Config{
		DatabaseURL: "https://bmstu-shalimov-default-rtdb.europe-west1.firebasedatabase.app",
	}

	app, err := firebase.NewApp(ctx, config, option.WithCredentialsFile("serviceAccountKey.json"))
	if err != nil {
		log.Fatalf("Failed to initialize Firebase app: %v", err)
	}

	dbClient, err := app.Database(ctx)
	if err != nil {
		log.Fatalf("Failed to create Firebase DB client: %v", err)
	}

	ref := dbClient.NewRef(fmt.Sprintf("/blocks/%d", block.Number().Uint64()))
	blockData := BlockData{
		Number:           block.Number().Uint64(),
		Time:             block.Time(),
		Difficulty:       block.Difficulty().Uint64(),
		Hash:             block.Hash().Hex(),
		TransactionCount: len(transactions),
		Transactions:     transactions,
	}

	if err := ref.Set(ctx, blockData); err != nil {
		log.Fatalf("Failed to write to Firebase: %v", err)
	}

	fmt.Printf("\nData for block %d successfully written to Firebase.\n", block.Number().Uint64())
	fmt.Printf("Verify at: https://etherscan.io/block/%d\n", block.Number().Uint64())
}
