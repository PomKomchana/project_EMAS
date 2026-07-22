const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

// ---------- ดึง token ของ user ทุกคนที่มี fcmToken ----------
/**
 * Fetches FCM tokens for all users that have one saved.
 * @return {Promise<string[]>} Array of FCM tokens.
 */
async function getAllTokens() {
  const snap = await db.collection("users").get();
  const tokens = [];
  snap.forEach((doc) => {
    const t = doc.data().fcmToken;
    if (t) tokens.push(t);
  });
  return tokens;
}

// ---------- ข่าวใหม่ถูกสร้าง → แจ้งทุกคน ----------
exports.onNewsCreated = onDocumentCreated("news/{newsId}", async (event) => {
  const data = event.data.data();
  const tokens = await getAllTokens();
  if (tokens.length === 0) return;

  await getMessaging().sendEachForMulticast({
    tokens,
    notification: {
      title: "📢 ประกาศใหม่",
      body: data.title || "มีประกาศใหม่จากแอดมิน",
    },
    data: {
      type: "news",
      newsId: event.params.newsId,
    },
  });
});

// ---------- Report ใหม่ → แจ้งทุกคน (low/medium/high) ----------
exports.onReportCreated = onDocumentCreated(
    "reports/{reportId}",
    async (event) => {
      const data = event.data.data();
      const tokens = await getAllTokens();
      if (tokens.length === 0) return;

      const severityLabel =
        data.severity === "high" ? "🔴 ร้ายแรง" :
        data.severity === "medium" ? "🟠 ปานกลาง" : "🟢 เล็กน้อย";

      await getMessaging().sendEachForMulticast({
        tokens,
        notification: {
          title: `แจ้งปัญหาใหม่ (${severityLabel})`,
          body: data.description || "มีการแจ้งปัญหาใหม่",
        },
        data: {
          type: "report",
          reportId: event.params.reportId,
        },
      });
    },
);
