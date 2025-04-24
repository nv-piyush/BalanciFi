const express = require("express");
const admin = require("firebase-admin");
const bodyParser = require("body-parser");
const axios = require("axios");
const multer = require("multer");
const cors = require("cors");
const dotenv = require("dotenv");
const moment = require("moment");
const geocoder = require("node-geocoder");
const currency = require("currency.js");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const path = require("path");

// Load environment variables
dotenv.config();

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const app = express();

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Serve static files from the current directory
app.use(express.static(__dirname));

// Configure multer to handle file uploads (for receipt scanning)
const upload = multer({ storage: multer.memoryStorage() });
const port = process.env.PORT || 3000;

// Initialize geocoder
const geo = geocoder({
  provider: "openstreetmap",
});

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key";

// Health-check endpoint
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "test-ui.html"));
});

// Enhanced expense categorization
const CATEGORIES = {
  Transportation: [
    "uber",
    "lyft",
    "taxi",
    "bus",
    "train",
    "metro",
    "gas",
    "parking",
  ],
  "Food & Dining": [
    "restaurant",
    "cafe",
    "food",
    "dining",
    "coffee",
    "lunch",
    "dinner",
  ],
  Groceries: [
    "grocery",
    "supermarket",
    "market",
    "walmart",
    "target",
    "costco",
  ],
  Entertainment: [
    "netflix",
    "spotify",
    "movie",
    "cinema",
    "concert",
    "game",
    "streaming",
  ],
  Shopping: ["amazon", "store", "shop", "mall", "clothing", "electronics"],
  "Bills & Utilities": [
    "electric",
    "water",
    "internet",
    "phone",
    "cable",
    "utility",
  ],
  Healthcare: ["pharmacy", "doctor", "hospital", "medical", "insurance"],
  Travel: ["hotel", "flight", "airbnb", "vacation", "travel"],
  Education: ["school", "university", "course", "book", "education"],
  "Personal Care": ["salon", "spa", "gym", "fitness", "beauty"],
  Miscellaneous: [], // Default category
};

function categorizeTransaction(title, amount) {
  title = title.toLowerCase();

  // Check for category keywords
  for (const [category, keywords] of Object.entries(CATEGORIES)) {
    if (keywords.some((keyword) => title.includes(keyword))) {
      return category;
    }
  }

  // If no match found, use amount-based categorization
  if (amount > 1000) return "Major Purchase";
  if (amount < 10) return "Small Expense";

  return "Miscellaneous";
}

/* ====================================================
   EXPENSES ENDPOINTS 
==================================================== */
// Get expenses for a specific user
app.get("/expenses/:userId", async (req, res) => {
  const userId = req.params.userId;
  try {
    const snapshot = await db
      .collection("Users")
      .doc(userId)
      .collection("Expenses")
      .get();
    let expenses = [];
    snapshot.forEach((doc) => {
      expenses.push({ id: doc.id, ...doc.data() });
    });
    res.json(expenses);
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

// Create a new expense for a user; auto-categorizes the transaction.
app.post("/expenses/:userId", async (req, res) => {
  const userId = req.params.userId;
  let expenseData = req.body;

  try {
    // Auto-categorize if category not provided
    if (!expenseData.category) {
      expenseData.category = categorizeTransaction(
        expenseData.title || "",
        expenseData.amount || 0
      );
    }

    // Add timestamp and user ID
    expenseData.userId = userId;
    expenseData.createdAt = moment().format();
    expenseData.updatedAt = moment().format();

    const docRef = await db
      .collection("Users")
      .doc(userId)
      .collection("Expenses")
      .add(expenseData);

    // Update budget tracking
    await updateBudgetTracking(userId, expenseData);

    res.json({ id: docRef.id, ...expenseData });
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

// Update an existing expense.
app.put("/expenses/:userId/:expenseId", async (req, res) => {
  const { userId, expenseId } = req.params;
  let expenseData = req.body;
  try {
    await db
      .collection("Users")
      .doc(userId)
      .collection("Expenses")
      .doc(expenseId)
      .update(expenseData);
    res.send("Expense updated");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

// Delete an expense.
app.delete("/expenses/:userId/:expenseId", async (req, res) => {
  const { userId, expenseId } = req.params;
  try {
    await db
      .collection("Users")
      .doc(userId)
      .collection("Expenses")
      .doc(expenseId)
      .delete();
    res.send("Expense deleted");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

// Get expenses with filters and analysis
app.get("/expenses/:userId", async (req, res) => {
  const userId = req.params.userId;
  const { startDate, endDate, category, minAmount, maxAmount } = req.query;

  try {
    let query = db.collection("Users").doc(userId).collection("Expenses");

    // Apply filters
    if (startDate) {
      query = query.where("createdAt", ">=", startDate);
    }
    if (endDate) {
      query = query.where("createdAt", "<=", endDate);
    }
    if (category) {
      query = query.where("category", "==", category);
    }
    if (minAmount) {
      query = query.where("amount", ">=", Number(minAmount));
    }
    if (maxAmount) {
      query = query.where("amount", "<=", Number(maxAmount));
    }

    const snapshot = await query.get();
    let expenses = [];
    let totalAmount = 0;
    let categoryBreakdown = {};

    snapshot.forEach((doc) => {
      const expense = { id: doc.id, ...doc.data() };
      expenses.push(expense);

      // Calculate totals and breakdowns
      totalAmount += Number(expense.amount);
      categoryBreakdown[expense.category] =
        (categoryBreakdown[expense.category] || 0) + Number(expense.amount);
    });

    // Calculate spending insights
    const insights = {
      totalAmount,
      categoryBreakdown,
      averageTransaction: totalAmount / expenses.length || 0,
      largestTransaction: Math.max(...expenses.map((e) => Number(e.amount))),
      smallestTransaction: Math.min(...expenses.map((e) => Number(e.amount))),
    };

    res.json({ expenses, insights });
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

/* ====================================================
   BUDGETS ENDPOINTS 
==================================================== */
app.get("/budgets/:userId", async (req, res) => {
  const userId = req.params.userId;
  try {
    const snapshot = await db
      .collection("Users")
      .doc(userId)
      .collection("Budgets")
      .get();
    let budgets = [];
    snapshot.forEach((doc) => {
      budgets.push({ id: doc.id, ...doc.data() });
    });
    res.json(budgets);
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.post("/budgets/:userId", async (req, res) => {
  const userId = req.params.userId;
  const budgetData = req.body; // { category, limit, period }
  try {
    const docRef = await db
      .collection("Users")
      .doc(userId)
      .collection("Budgets")
      .add(budgetData);
    res.json({ id: docRef.id });
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.put("/budgets/:userId/:budgetId", async (req, res) => {
  const { userId, budgetId } = req.params;
  const budgetData = req.body;
  try {
    await db
      .collection("Users")
      .doc(userId)
      .collection("Budgets")
      .doc(budgetId)
      .update(budgetData);
    res.send("Budget updated");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.delete("/budgets/:userId/:budgetId", async (req, res) => {
  const { userId, budgetId } = req.params;
  try {
    await db
      .collection("Users")
      .doc(userId)
      .collection("Budgets")
      .doc(budgetId)
      .delete();
    res.send("Budget deleted");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

// Get budget with spending analysis
app.get("/budgets/:userId", async (req, res) => {
  const userId = req.params.userId;

  try {
    const budgetsSnapshot = await db
      .collection("Users")
      .doc(userId)
      .collection("Budgets")
      .get();
    let budgets = [];
    let totalBudget = 0;
    let totalSpent = 0;

    budgetsSnapshot.forEach((doc) => {
      const budget = { id: doc.id, ...doc.data() };
      budgets.push(budget);
      totalBudget += Number(budget.limit);
      totalSpent += Number(budget.spent || 0);
    });

    // Calculate budget insights
    const insights = {
      totalBudget,
      totalSpent,
      remainingBudget: totalBudget - totalSpent,
      utilizationPercentage: (totalSpent / totalBudget) * 100 || 0,
      budgets,
    };

    res.json(insights);
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

/* ====================================================
   SAVINGS GOALS ENDPOINTS 
==================================================== */
app.get("/savings/:userId", async (req, res) => {
  const userId = req.params.userId;
  try {
    const snapshot = await db
      .collection("Users")
      .doc(userId)
      .collection("Savings")
      .get();
    let savings = [];
    snapshot.forEach((doc) => {
      savings.push({ id: doc.id, ...doc.data() });
    });
    res.json(savings);
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.post("/savings/:userId", async (req, res) => {
  const userId = req.params.userId;
  const savingsData = req.body; // { goalName, targetAmount, currentAmount, dueDate }
  try {
    const docRef = await db
      .collection("Users")
      .doc(userId)
      .collection("Savings")
      .add(savingsData);
    res.json({ id: docRef.id });
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.put("/savings/:userId/:savingsId", async (req, res) => {
  const { userId, savingsId } = req.params;
  const savingsData = req.body;
  try {
    await db
      .collection("Users")
      .doc(userId)
      .collection("Savings")
      .doc(savingsId)
      .update(savingsData);
    res.send("Savings goal updated");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.delete("/savings/:userId/:savingsId", async (req, res) => {
  const { userId, savingsId } = req.params;
  try {
    await db
      .collection("Users")
      .doc(userId)
      .collection("Savings")
      .doc(savingsId)
      .delete();
    res.send("Savings goal deleted");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

/* ====================================================
   FINANCIAL INSIGHTS ENDPOINT
==================================================== */
// Dummy aggregation to return insights data.
app.get("/insights/:userId", async (req, res) => {
  const userId = req.params.userId;
  try {
    const expensesSnapshot = await db
      .collection("Users")
      .doc(userId)
      .collection("Expenses")
      .get();
    let totalSpent = 0;
    expensesSnapshot.forEach((doc) => {
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
app.post("/receipt/:userId", upload.single("receipt"), async (req, res) => {
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
app.get("/currency/convert", async (req, res) => {
  const { from, to, amount } = req.query;
  const fixedRate = 1.1; // Dummy conversion rate.
  const convertedAmount = (Number(amount) * fixedRate).toFixed(2);
  res.json({ from, to, originalAmount: amount, convertedAmount });
});

/* ====================================================
   BILLS & REMINDERS ENDPOINTS 
==================================================== */
app.get("/bills/:userId", async (req, res) => {
  const userId = req.params.userId;
  try {
    const snapshot = await db
      .collection("Users")
      .doc(userId)
      .collection("Bills")
      .get();
    let bills = [];
    snapshot.forEach((doc) => {
      bills.push({ id: doc.id, ...doc.data() });
    });
    res.json(bills);
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.post("/bills/:userId", async (req, res) => {
  const userId = req.params.userId;
  const billData = req.body; // { billName, dueDate, amount, reminder }
  try {
    const docRef = await db
      .collection("Users")
      .doc(userId)
      .collection("Bills")
      .add(billData);
    res.json({ id: docRef.id });
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.put("/bills/:userId/:billId", async (req, res) => {
  const { userId, billId } = req.params;
  const billData = req.body;
  try {
    await db
      .collection("Users")
      .doc(userId)
      .collection("Bills")
      .doc(billId)
      .update(billData);
    res.send("Bill updated");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.delete("/bills/:userId/:billId", async (req, res) => {
  const { userId, billId } = req.params;
  try {
    await db
      .collection("Users")
      .doc(userId)
      .collection("Bills")
      .doc(billId)
      .delete();
    res.send("Bill deleted");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

/* ====================================================
   REWARDS ENDPOINTS (GAMIFICATION)
==================================================== */
app.get("/rewards/:userId", async (req, res) => {
  const userId = req.params.userId;
  try {
    const snapshot = await db
      .collection("Users")
      .doc(userId)
      .collection("Rewards")
      .get();
    let rewards = [];
    snapshot.forEach((doc) => {
      rewards.push({ id: doc.id, ...doc.data() });
    });
    res.json(rewards);
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.post("/rewards/:userId", async (req, res) => {
  const userId = req.params.userId;
  const rewardData = req.body; // { rewardName, earnedDate, points }
  try {
    const docRef = await db
      .collection("Users")
      .doc(userId)
      .collection("Rewards")
      .add(rewardData);
    res.json({ id: docRef.id });
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.put("/rewards/:userId/:rewardId", async (req, res) => {
  const { userId, rewardId } = req.params;
  const rewardData = req.body;
  try {
    await db
      .collection("Users")
      .doc(userId)
      .collection("Rewards")
      .doc(rewardId)
      .update(rewardData);
    res.send("Reward updated");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.delete("/rewards/:userId/:rewardId", async (req, res) => {
  const { userId, rewardId } = req.params;
  try {
    await db
      .collection("Users")
      .doc(userId)
      .collection("Rewards")
      .doc(rewardId)
      .delete();
    res.send("Reward deleted");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

/* ====================================================
   USER PROFILE & SETTINGS ENDPOINTS 
==================================================== */
app.get("/profile/:userId", async (req, res) => {
  const userId = req.params.userId;
  try {
    const doc = await db.collection("Users").doc(userId).get();
    if (doc.exists) {
      res.json(doc.data());
    } else {
      res.status(404).send("Profile not found");
    }
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.put("/profile/:userId", async (req, res) => {
  const userId = req.params.userId;
  const profileData = req.body;
  try {
    await db.collection("Users").doc(userId).set(profileData, { merge: true });
    res.send("Profile updated");
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

// Enhanced authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) {
    return res.status(401).send("Access token required");
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).send("Invalid token");
    }
    req.user = user;
    next();
  });
};

// Enhanced user signup
app.post("/signup", async (req, res) => {
  const {
    email,
    password,
    displayName,
    currencyPreference = "USD",
    language = "en",
  } = req.body;

  if (!email || !password) {
    return res.status(400).send("Email and password are required.");
  }

  try {
    // Create the user in Firebase Auth
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: displayName || "",
    });

    // Hash password for storage
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create a user profile document in Firestore
    const userProfile = {
      displayName: displayName || "",
      email: email,
      settings: {
        darkMode: false,
        currency: currencyPreference,
        language: language,
        notifications: {
          budgetAlerts: true,
          savingsGoals: true,
          rewards: true,
        },
      },
      createdAt: moment().format(),
      lastLogin: moment().format(),
      password: hashedPassword, // Store hashed password
    };

    // Save the profile document
    await db.collection("Users").doc(userRecord.uid).set(userProfile);

    // Generate JWT token
    const token = jwt.sign({ uid: userRecord.uid, email: email }, JWT_SECRET, {
      expiresIn: "24h",
    });

    res.json({
      uid: userRecord.uid,
      token,
      message: "User created successfully.",
    });
  } catch (error) {
    console.error("Error creating user:", error);
    res.status(500).send(error.toString());
  }
});

// User login
app.post("/login", async (req, res) => {
  const { email, password } = req.body;

  try {
    const userSnapshot = await db
      .collection("Users")
      .where("email", "==", email)
      .limit(1)
      .get();

    if (userSnapshot.empty) {
      return res.status(404).send("User not found");
    }

    const userDoc = userSnapshot.docs[0];
    const userData = userDoc.data();

    // Verify password
    const validPassword = await bcrypt.compare(password, userData.password);
    if (!validPassword) {
      return res.status(401).send("Invalid password");
    }

    // Update last login
    await db.collection("Users").doc(userDoc.id).update({
      lastLogin: moment().format(),
    });

    // Generate new token
    const token = jwt.sign({ uid: userDoc.id, email: email }, JWT_SECRET, {
      expiresIn: "24h",
    });

    res.json({
      uid: userDoc.id,
      token,
      message: "Login successful",
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).send(error.toString());
  }
});

// Update user settings
app.put("/users/:userId/settings", authenticateToken, async (req, res) => {
  const userId = req.params.userId;
  const settings = req.body;

  try {
    await db.collection("Users").doc(userId).update({
      settings: settings,
    });
    res.json({ message: "Settings updated successfully" });
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

// Get user profile
app.get("/users/:userId/profile", authenticateToken, async (req, res) => {
  const userId = req.params.userId;

  try {
    const doc = await db.collection("Users").doc(userId).get();
    if (!doc.exists) {
      return res.status(404).send("User not found");
    }

    const userData = doc.data();
    // Remove sensitive data
    delete userData.password;

    res.json(userData);
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

// Helper function to update budget tracking
async function updateBudgetTracking(userId, expense) {
  try {
    const budgetRef = db
      .collection("Users")
      .doc(userId)
      .collection("Budgets")
      .where("category", "==", expense.category)
      .where("period", "==", "monthly");

    const budgetSnapshot = await budgetRef.get();

    if (!budgetSnapshot.empty) {
      const budgetDoc = budgetSnapshot.docs[0];
      const budget = budgetDoc.data();

      // Update spent amount
      const newSpent = (budget.spent || 0) + Number(expense.amount);
      await budgetDoc.ref.update({ spent: newSpent });

      // Check if budget limit is exceeded
      if (newSpent > budget.limit) {
        // You could add notification logic here
        console.log(`Budget exceeded for ${expense.category}`);
      }
    }
  } catch (error) {
    console.error("Error updating budget tracking:", error);
  }
}

// Currency mapping for countries
const COUNTRY_CURRENCIES = {
  US: "USD",
  GB: "GBP",
  CA: "CAD",
  AU: "AUD",
  IN: "INR",
  JP: "JPY",
  EU: "EUR",
  CN: "CNY",
  BR: "BRL",
  MX: "MXN",
  // Add more country-currency mappings as needed
};

// Helper function to get currency from coordinates
async function getCurrencyFromLocation(latitude, longitude) {
  try {
    const res = await geo.reverse({ lat: latitude, lon: longitude });
    if (res && res[0]) {
      const countryCode = res[0].countryCode;
      return COUNTRY_CURRENCIES[countryCode] || "USD"; // Default to USD if country not found
    }
    return "USD"; // Default to USD if location not found
  } catch (error) {
    console.error("Error getting currency from location:", error);
    return "USD"; // Default to USD on error
  }
}

// Update user's currency based on location
app.post(
  "/users/:userId/update-currency",
  authenticateToken,
  async (req, res) => {
    const userId = req.params.userId;
    const { latitude, longitude } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).send("Latitude and longitude are required");
    }

    try {
      // Get currency based on location
      const currency = await getCurrencyFromLocation(latitude, longitude);

      // Update user's currency preference
      await db
        .collection("Users")
        .doc(userId)
        .update({
          "settings.currency": currency,
          "settings.lastLocationUpdate": moment().format(),
          "settings.location": {
            latitude,
            longitude,
            lastUpdated: moment().format(),
          },
        });

      res.json({
        message: "Currency updated successfully",
        currency,
        updatedAt: moment().format(),
      });
    } catch (error) {
      res.status(500).send(error.toString());
    }
  }
);

// Get currency conversion rates
app.get("/currency/rates", authenticateToken, async (req, res) => {
  const { base = "USD" } = req.query;

  try {
    // In production, replace this with a real currency API
    const dummyRates = {
      USD: 1,
      EUR: 0.92,
      GBP: 0.79,
      JPY: 151.82,
      AUD: 1.52,
      CAD: 1.36,
      CNY: 7.24,
      INR: 83.31,
      BRL: 5.04,
      MXN: 16.65,
    };

    // Calculate rates relative to base currency
    const baseRate = dummyRates[base];
    const rates = {};

    for (const [currency, rate] of Object.entries(dummyRates)) {
      rates[currency] = rate / baseRate;
    }

    res.json({
      base,
      rates,
      lastUpdated: moment().format(),
    });
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

// Convert amount between currencies
app.get("/currency/convert", authenticateToken, async (req, res) => {
  const { from, to, amount } = req.query;

  if (!from || !to || !amount) {
    return res
      .status(400)
      .send("From currency, to currency, and amount are required");
  }

  try {
    // Get conversion rates
    const ratesResponse = await axios.get(
      `http://localhost:${port}/currency/rates?base=${from}`
    );
    const rates = ratesResponse.data.rates;

    if (!rates[to]) {
      return res.status(400).send("Invalid target currency");
    }

    const convertedAmount = currency(amount).multiply(rates[to]).value;

    res.json({
      from,
      to,
      originalAmount: Number(amount),
      convertedAmount,
      rate: rates[to],
      timestamp: moment().format(),
    });
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

// Get user's current currency settings
app.get("/users/:userId/currency", authenticateToken, async (req, res) => {
  const userId = req.params.userId;

  try {
    const userDoc = await db.collection("Users").doc(userId).get();
    if (!userDoc.exists) {
      return res.status(404).send("User not found");
    }

    const userData = userDoc.data();
    const currencySettings = {
      currency: userData.settings.currency,
      lastLocationUpdate: userData.settings.lastLocationUpdate,
      location: userData.settings.location,
    };

    res.json(currencySettings);
  } catch (error) {
    res.status(500).send(error.toString());
  }
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
