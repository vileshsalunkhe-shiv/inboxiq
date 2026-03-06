# InboxIQ App Icon - Figma Tutorial (Better Instructions)

**Design:** AI Envelope with gradient + sparkles
**Time:** 20-30 minutes
**Difficulty:** Beginner-friendly
**Result:** 1024×1024 PNG app icon

---

## 🎯 What We're Building

A professional app icon with:
- Gradient background (blue → purple)
- White envelope shape
- Gold sparkle effects
- Clean, minimal, recognizable

---

## 📋 Step-by-Step (Figma)

### Step 1: Set Up (2 minutes)

1. Go to **figma.com** (free account)
2. Click **"New design file"**
3. Press **F** key (Frame tool) or click Frame in toolbar
4. In right panel, set size to **1024 × 1024**
5. Name the frame: **"InboxIQ Icon"**

---

### Step 2: Gradient Background (3 minutes)

1. **Select the frame** (click the frame name or border)
2. In right panel, find **"Fill"** section
3. Click the **color square**
4. Click **"Linear"** (changes from solid to gradient)
5. Set gradient colors:
   - **First stop (left):** Click color → Type `007AFF` in hex field
   - **Second stop (right):** Click color → Type `5856D6` in hex field
6. **Rotate gradient:**
   - Drag the gradient line from top-left to bottom-right (diagonal)
   - Should go from upper-left corner to lower-right corner

**Result:** Blue-to-purple diagonal gradient background

---

### Step 3: Draw Envelope Body (5 minutes)

1. Press **R** key (Rectangle tool)
2. Click and drag to create rectangle approximately **600×450** pixels
3. In right panel:
   - Width: `600`
   - Height: `450`
   - X position: `212` (centers horizontally)
   - Y position: `287` (centers vertically)

4. **Style the rectangle:**
   - Fill: Click color → Type `FFFFFF` (white)
   - Corner radius: Type `16` in corner radius field
   
5. **Add shadow:**
   - In right panel, find **"Effects"**
   - Click **+** button
   - Select **"Drop Shadow"**
   - Settings:
     - X: `0`
     - Y: `8`
     - Blur: `24`
     - Color: Black at 15% opacity

**Result:** White rounded rectangle with subtle shadow

---

### Step 4: Draw Envelope Flap (5 minutes)

1. Press **P** key (Pen tool) or click triangle icon
2. Click **polygon** icon → Select **triangle**
3. Draw triangle approximately **600px wide × 200px tall**
4. Position it **overlapping top of rectangle**
5. **Rotate triangle:**
   - With triangle selected, look for rotation handle at top
   - Drag to flip it so point faces **DOWN** (like envelope flap)

6. **Style the triangle:**
   - Fill: `FFFFFF` (white)
   - Effects: Same drop shadow as rectangle

7. **Align both shapes:**
   - Select rectangle (click it)
   - Hold **Shift** and click triangle (both selected)
   - Right-click → **"Align horizontal centers"**

**Result:** Envelope shape (rectangle + triangle flap)

---

### Step 5: Add Sparkles (7 minutes)

**Using Figma's built-in shapes:**

1. Press **P** key (Pen tool)
2. Click **"Star"** icon in toolbar
3. Draw a small star (about **32×32 pixels**)
4. In right panel:
   - Fill: Type `FFD60A` (gold)
   - Count: `4` or `8` (4-point or 8-point star)

5. **Add glow effect:**
   - Effects → **+ → Layer Blur**
   - Amount: `8`
   - Or use **Drop Shadow** with:
     - X: `0`, Y: `0`
     - Blur: `12`
     - Spread: `4`
     - Color: `FFD60A` at 60% opacity

6. **Duplicate and place sparkles:**
   - Select star
   - Hold **Alt/Option** and drag to duplicate
   - Or press **Cmd+D** / **Ctrl+D** to duplicate
   - Place **6-8 sparkles** around envelope:
     - 2-3 in top-left area
     - 2-3 in top-right area
     - 1-2 in bottom corners
   - **Vary sizes:** Make some 24px, some 32px, some 48px
   - **Rotate:** Select each star and type different angles (15°, 45°, 120°, etc.)

**Result:** Sparkles scattered around envelope

---

### Step 6: Layer Order (2 minutes)

Make sure layers are in correct order (from front to back):

1. Open **Layers panel** (left side)
2. Drag layers to arrange:
   - Top: Sparkles (in front)
   - Middle: Envelope shapes (triangle, rectangle)
   - Bottom: Gradient background frame

**Or:**
- Right-click shapes → **"Bring to front"** or **"Send to back"**

---

### Step 7: Final Adjustments (3 minutes)

1. **Center everything:**
   - Select all (Cmd+A / Ctrl+A)
   - Right-click → **"Align vertical centers"**
   - Right-click → **"Align horizontal centers"**

2. **Check composition:**
   - Zoom out (Cmd+- / Ctrl+-)
   - Does it look balanced?
   - Keep elements 100px away from edges

3. **Test at small size:**
   - Zoom to 10% (bottom-left corner)
   - Can you still recognize the envelope?
   - If sparkles look cluttered, remove 1-2

---

### Step 8: Export (3 minutes)

1. **Select the frame** (click frame name in left panel)
2. In right panel, scroll to **"Export"** section
3. Click **"+"** button
4. Settings:
   - Format: **PNG**
   - Size: **1x** (keeps 1024×1024)
   - Suffix: Leave blank or type `-icon`
5. Click **"Export InboxIQ Icon"** button
6. Save as: **InboxIQ-Icon-1024.png**

---

## ✅ Done!

You now have a 1024×1024 PNG file ready for Xcode.

---

## 🎨 Color Reference (Copy-Paste)

```
Background Gradient:
  Start: #007AFF (iOS blue)
  End:   #5856D6 (purple)

Envelope:
  Fill:  #FFFFFF (white)
  
Sparkles:
  Fill:  #FFD60A (gold)
```

---

## 🖼️ Import to Xcode

1. Open **InboxIQ.xcodeproj**
2. Left sidebar → **Assets.xcassets**
3. Click **AppIcon**
4. Drag **InboxIQ-Icon-1024.png** to the **"1024pt"** slot
5. Xcode generates all other sizes automatically
6. Build and run to see your icon!

---

## 💡 Pro Tips

**If envelope looks too small:**
- Select rectangle and triangle
- Increase size to 700×525 and 700×250

**If sparkles are too busy:**
- Use only 4-6 sparkles instead of 8
- Make them smaller (24-32px instead of 32-48px)

**If gradient is too subtle:**
- Try steeper angle (straight vertical or horizontal)
- Or adjust colors to have more contrast

**Quick star shortcut:**
- Press **P** (Pen) → **Click star icon** → **Draw**
- Or search Figma community for "sparkle icon" to copy

---

## 🆘 Troubleshooting

**Can't find gradient option:**
- Click the color square in Fill section
- Look for "Solid / Linear / Radial" options at top of color picker

**Stars look weird:**
- Select star → Right panel → "Count" field → Set to 4 or 8
- Inner radius: 50% for balanced star

**Can't export:**
- Make sure you selected the **frame**, not individual shapes
- Frame should be 1024×1024 (check in right panel)

**Export is blurry:**
- Ensure export is set to PNG (not JPG)
- Size should be 1x (not 2x or 3x for this case)

---

## 🎯 What Makes This Easier Than Canva

1. **Precise positioning** - X/Y coordinates in right panel
2. **Perfect alignment** - Built-in alignment tools
3. **Exact colors** - Hex code input (no color picker hunting)
4. **Layer control** - Clear layer hierarchy in left panel
5. **Duplicate fast** - Alt+drag or Cmd+D
6. **Export control** - Better export options

---

**Time estimate:** 20-30 minutes (faster than Canva, more precise)

**Need help?** Share your Figma link and I can see what you're working on!
