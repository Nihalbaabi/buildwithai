// This script seeds user credentials into Firebase
// Run with: node seedUsers.mjs
import { initializeApp } from "firebase/app";
import { getDatabase, ref, set } from "firebase/database";

const firebaseConfig = {
  apiKey: "AIzaSyDC0PuenM-vzg9KvpRI_AvhlLHf4cdzKeo",
  authDomain: "eco-track-e75ad.firebaseapp.com",
  databaseURL: "https://eco-track-e75ad-default-rtdb.asia-southeast1.firebasedatabase.app",
  projectId: "eco-track-e75ad",
  storageBucket: "eco-track-e75ad.firebasestorage.app",
  messagingSenderId: "1043700479151",
  appId: "1:1043700479151:web:f04ff956d246658a58d05a",
};

const app = initializeApp(firebaseConfig);
const database = getDatabase(app);

async function seedUsers() {
  console.log("Seeding user credentials...");
  
  await set(ref(database, "users/user1/password"), "user@1");
  console.log("✅ users/user1/password = user@1");
  
  await set(ref(database, "users/user2/password"), "user@2");
  console.log("✅ users/user2/password = user@2");
  
  console.log("Done! You can now log in with:");
  console.log("  User ID: user1  Password: user@1");
  console.log("  User ID: user2  Password: user@2");
  process.exit(0);
}

seedUsers().catch(console.error);
