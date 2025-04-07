# Firestore Schema & Categorization Logic

## 🔧 Firestore Document Structure

```
users (collection)
└── {userId} (document)
    └── transactions (subcollection)
        └── {transactionId}
            ├── amount: double
            ├── category: string
            ├── merchant: string
            ├── description: string
            ├── date: timestamp
```

## 🧠 Categorization Logic

1. Each transaction is matched against a list of keywords under predefined categories.
2. Keyword match is case-insensitive and checks merchant string.
3. If no match is found, transaction is marked as `"Uncategorized"`.

## 🧪 Testing

Tested using mock transactions and verified category assignment for known merchants:

- Starbucks → Food
- Uber → Transport
- Amazon → Shopping
