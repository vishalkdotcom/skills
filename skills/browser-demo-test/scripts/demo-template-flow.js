/**
 * Tier B flow template — rename to flow.js in your scenario folder.
 * Copy AC text from vault qa-plan.md into showAc descriptions.
 */
async (page) => {
  const videoPath = process.env.DEMO_VIDEO_PATH || 'demo.webm';
  const loginUrl = process.env.DEMO_LOGIN_URL || 'http://localhost:3001/next/login';

  const showAc = async (title, description) => {
    await page.screencast.showChapter(title, { description, duration: 2500 });
  };

  const passBadge = async (text) => {
    await page.screencast.showOverlay(
      `<div style="position:absolute;top:12px;right:12px;padding:8px 14px;
        background:rgba(22,101,52,0.92);border-radius:8px;font-size:14px;color:white;
        font-family:system-ui,sans-serif;">✓ ${text}</div>`,
      { duration: 2000 },
    );
  };

  await page.screencast.start({ path: videoPath, size: { width: 1920, height: 1080 } });
  await page.screencast.showActions({ duration: 800, position: 'top-right', cursor: 'pointer' });

  await showAc('AC1: …', 'Given …, when …, then …');
  await page.goto(loginUrl, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(2000);

  await passBadge('Replace with expected outcome from qa-plan');
  await page.waitForTimeout(1500);

  await page.screencast.stop();
};
