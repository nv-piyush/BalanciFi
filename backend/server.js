const express = require('express');
const admin = require('firebase-admin');
const bodyParser = require('body-parser');
const axios = require('axios');
const multer = require('multer');

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const app = express();
app.use(bodyParser.json());

// Configure multer to handle file uploads (for receipt scanning)
const upload = multer({ storage: multer.memoryStorage() });
const port = process.env.PORT || 3000;

// Health-check endpoint
app.get('/', (req, res) => {
  res.send('BalanciFi Backend API is running');
});

/*  
  HELPER: A simple rule-based transaction categorization function.
  In production, replace or extend this with more sophisticated logic or ML.
*/
function categorizeTransaction(title) {
  title = title.toLowerCase();
  if (title.includes('uber') || title.includes('lyft')) {
    return 'Transportation';
  } else if (title.includes('netflix') || title.includes('spotify')) {
    return 'Entertainment';
  } else if (title.includes('grocery') || title.includes('supermarket')) {
    return 'Groceries';
  }
  return 'Miscellaneous';
}

/* ====================================================
   EXPENSES ENDPOINTS 
==================================================== */
// Get expenses for a specific user
app.get('/expenses/:userId', async (req, res) => {
  const userId = req.params.userId;
  try {
    const snapshot = await db.collection('Users').doc(userId).collection('Expenses').get();
    let expenses = [];
    snapshot.forEach(doc => {
      expenses.push({ id: doc.id, ...doc.data() });
    });
    res.json(expenses);
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

// Create a new expense for a user; auto-categorizes the transaction.
app.post('/expenses/:userId', async (req, res) => {
  const userId = req.params.userId;
  let expenseData = req.body;
  expenseData.category = categorizeTransaction(expenseData.title || '');
  try {
    const docRef = await db.collection('Users').doc(userId).collection('Expenses').add(expenseData);
    res.json({ id: docRef.id });
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

// Update an existing expense.
app.put('/expenses/:userId/:expenseId', async (req, res) => {
  const { userId, expenseId } = req.params;
  let expenseData = req.body;
  try {
    await db.collection('Users').doc(userId).collection('Expenses').doc(expenseId).update(expenseData);
    res.send("Expense updated");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

// Delete an expense.
app.delete('/expenses/:userId/:expenseId', async (req, res) => {
  const { userId, expenseId } = req.params;
  try {
    await db.collection('Users').doc(userId).collection('Expenses').doc(expenseId).delete();
    res.send("Expense deleted");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

/* ====================================================
   BUDGETS ENDPOINTS 
==================================================== */
app.get('/budgets/:userId', async (req, res) => {
  const userId = req.params.userId;
  try {
    const snapshot = await db.collection('Users').doc(userId).collection('Budgets').get();
    let budgets = [];
    snapshot.forEach(doc => {
      budgets.push({ id: doc.id, ...doc.data() });
    });
    res.json(budgets);
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.post('/budgets/:userId', async (req, res) => {
  const userId = req.params.userId;
  const budgetData = req.body; // { category, limit, period }
  try {
    const docRef = await db.collection('Users').doc(userId).collection('Budgets').add(budgetData);
    res.json({ id: docRef.id });
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.put('/budgets/:userId/:budgetId', async (req, res) => {
  const { userId, budgetId } = req.params;
  const budgetData = req.body;
  try {
    await db.collection('Users').doc(userId).collection('Budgets').doc(budgetId).update(budgetData);
    res.send("Budget updated");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.delete('/budgets/:userId/:budgetId', async (req, res) => {
  const { userId, budgetId } = req.params;
  try {
    await db.collection('Users').doc(userId).collection('Budgets').doc(budgetId).delete();
    res.send("Budget deleted");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

/* ====================================================
   SAVINGS GOALS ENDPOINTS 
==================================================== */
app.get('/savings/:userId', async (req, res) => {
  const userId = req.params.userId;
  try {
    const snapshot = await db.collection('Users').doc(userId).collection('Savings').get();
    let savings = [];
    snapshot.forEach(doc => {
      savings.push({ id: doc.id, ...doc.data() });
    });
    res.json(savings);
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.post('/savings/:userId', async (req, res) => {
  const userId = req.params.userId;
  const savingsData = req.body;  // { goalName, targetAmount, currentAmount, dueDate }
  try {
    const docRef = await db.collection('Users').doc(userId).collection('Savings').add(savingsData);
    res.json({ id: docRef.id });
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.put('/savings/:userId/:savingsId', async (req, res) => {
  const { userId, savingsId } = req.params;
  const savingsData = req.body;
  try {
    await db.collection('Users').doc(userId).collection('Savings').doc(savingsId).update(savingsData);
    res.send("Savings goal updated");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.delete('/savings/:userId/:savingsId', async (req, res) => {
  const { userId, savingsId } = req.params;
  try {
    await db.collection('Users').doc(userId).collection('Savings').doc(savingsId).delete();
    res.send("Savings goal deleted");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

/* ====================================================
   FINANCIAL INSIGHTS ENDPOINT
==================================================== */
// Dummy aggregation to return insights data.
app.get('/insights/:userId', async (req, res) => {
  const userId = req.params.userId;
  try {
    const expensesSnapshot = await db.collection('Users').doc(userId).collection('Expenses').get();
    let totalSpent = 0;
    expensesSnapshot.forEach(doc => {
      totalSpent += Number(doc.data().amount);
    });
    const insightsData = {
      totalSpent: totalSpent,
      savingsPercentage: 20, // Dummy percentage.
      recommendedBudgetAdjustment: "Increase budget for groceries",
    };
    res.json(insightsData);
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

/* ====================================================
   RECEIPT SCANNING ENDPOINT (SIMULATED)
==================================================== */
app.post('/receipt/:userId', upload.single('receipt'), async (req, res) => {
  const userId = req.params.userId;
  if (!req.file) {
    return res.status(400).send("No file uploaded");
  }
  // In production, integrate with an OCR service (e.g., Google Vision API).
  const dummyExtractedText = "Dummy receipt text: Walmart $45.67 on 2025-04-09";
  res.json({ extractedText: dummyExtractedText });
});

/* ====================================================
   CURRENCY CONVERSION ENDPOINT (SIMULATED)
==================================================== */
app.get('/currency/convert', async (req, res) => {
  const { from, to, amount } = req.query;
  const fixedRate = 1.1; // Dummy conversion rate.
  const convertedAmount = (Number(amount) * fixedRate).toFixed(2);
  res.json({ from, to, originalAmount: amount, convertedAmount });
});

/* ====================================================
   BILLS & REMINDERS ENDPOINTS 
==================================================== */
app.get('/bills/:userId', async (req, res) => {
  const userId = req.params.userId;
  try {
    const snapshot = await db.collection('Users').doc(userId).collection('Bills').get();
    let bills = [];
    snapshot.forEach(doc => {
      bills.push({ id: doc.id, ...doc.data() });
    });
    res.json(bills);
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.post('/bills/:userId', async (req, res) => {
  const userId = req.params.userId;
  const billData = req.body;  // { billName, dueDate, amount, reminder }
  try {
    const docRef = await db.collection('Users').doc(userId).collection('Bills').add(billData);
    res.json({ id: docRef.id });
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.put('/bills/:userId/:billId', async (req, res) => {
  const { userId, billId } = req.params;
  const billData = req.body;
  try {
    await db.collection('Users').doc(userId).collection('Bills').doc(billId).update(billData);
    res.send("Bill updated");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.delete('/bills/:userId/:billId', async (req, res) => {
  const { userId, billId } = req.params;
  try {
    await db.collection('Users').doc(userId).collection('Bills').doc(billId).delete();
    res.send("Bill deleted");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

/* ====================================================
   REWARDS ENDPOINTS (GAMIFICATION)
==================================================== */
app.get('/rewards/:userId', async (req, res) => {
  const userId = req.params.userId;
  try {
    const snapshot = await db.collection('Users').doc(userId).collection('Rewards').get();
    let rewards = [];
    snapshot.forEach(doc => {
      rewards.push({ id: doc.id, ...doc.data() });
    });
    res.json(rewards);
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.post('/rewards/:userId', async (req, res) => {
  const userId = req.params.userId;
  const rewardData = req.body;  // { rewardName, earnedDate, points }
  try {
    const docRef = await db.collection('Users').doc(userId).collection('Rewards').add(rewardData);
    res.json({ id: docRef.id });
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.put('/rewards/:userId/:rewardId', async (req, res) => {
  const { userId, rewardId } = req.params;
  const rewardData = req.body;
  try {
    await db.collection('Users').doc(userId).collection('Rewards').doc(rewardId).update(rewardData);
    res.send("Reward updated");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.delete('/rewards/:userId/:rewardId', async (req, res) => {
  const { userId, rewardId } = req.params;
  try {
    await db.collection('Users').doc(userId).collection('Rewards').doc(rewardId).delete();
    res.send("Reward deleted");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

/* ====================================================
   USER PROFILE & SETTINGS ENDPOINTS 
==================================================== */
app.get('/profile/:userId', async (req, res) => {
  const userId = req.params.userId;
  try {
    const doc = await db.collection('Users').doc(userId).get();
    if (doc.exists) {
      res.json(doc.data());
    } else {
      res.status(404).send('Profile not found');
    }
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.put('/profile/:userId', async (req, res) => {
  const userId = req.params.userId;
  const profileData = req.body;
  try {
    await db.collection('Users').doc(userId).set(profileData, { merge: true });
    res.send("Profile updated");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
