const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Add Transaction
exports.addTransaction = functions.https.onRequest(async (req, res) => {
    try {
        const { uid, amount, category, date, description } = req.body;
        const transactionRef = db.collection("users").doc(uid).collection("transactions");
        const newTxn = await transactionRef.add({
            amount,
            category,
            date: new Date(date),
            description,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        res.status(200).send({ success: true, id: newTxn.id });
    } catch (err) {
        console.error("Error adding transaction:", err);
        res.status(500).send({ success: false, error: err.message });
    }
});

// Get Transactions
exports.getTransactions = functions.https.onRequest(async (req, res) => {
    try {
        const uid = req.query.uid;
        const snapshot = await db.collection("users").doc(uid).collection("transactions").orderBy("date", "desc").get();
        const transactions = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        res.status(200).send(transactions);
    } catch (err) {
        console.error("Error fetching transactions:", err);
        res.status(500).send({ success: false, error: err.message });
    }
});
