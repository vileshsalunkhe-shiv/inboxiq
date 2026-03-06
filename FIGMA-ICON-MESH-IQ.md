# InboxIQ App Icon - Vibrant Mesh + IQ Text
**Design:** Colorful gradient mesh background with bold "IQ" text (EcoFlow EF style)
**Created:** 2026-03-04

## Design Concept
- **Base:** Vibrant mesh gradient (purple, blue, pink, orange)
- **Overlay:** Bold "IQ" text in modern sans-serif (similar to EcoFlow's "EF")
- **Style:** Contemporary, energetic, tech-forward
- **Size:** 1024×1024 PNG

## Figma Tutorial

### Step 1: Create Canvas
1. Open Figma (figma.com)
2. Create new file: **"InboxIQ App Icon"**
3. Press **F** (Frame tool)
4. Create frame: **1024 × 1024 px**
5. Name it: **"App Icon"**

### Step 2: Create Mesh Gradient Background
1. Select the frame
2. Press **R** (Rectangle tool)
3. Draw rectangle covering entire frame (1024×1024)
4. In right panel, remove stroke (click stroke, set to none)
5. Click **Fill** → Select **gradient mesh** or use multiple gradients:

**Option A: Mesh Gradient (if available)**
1. Fill → Gradient → Mesh
2. Add control points and set colors:
   - Top-left: `#8B5CF6` (purple)
   - Top-right: `#EC4899` (pink)
   - Bottom-left: `#3B82F6` (blue)
   - Bottom-right: `#F97316` (orange)

**Option B: Radial Gradients (layer multiple)**
1. Create 3-4 circles with radial gradients
2. Set different colors and positions
3. Set blend mode to **Screen** or **Color Dodge**
4. Adjust opacity (60-80%)
5. Colors to use:
   - Purple: `#8B5CF6`
   - Blue: `#3B82F6`
   - Pink: `#EC4899`
   - Orange: `#F97316`

### Step 3: Add "IQ" Text
1. Press **T** (Text tool)
2. Click center of frame
3. Type: **IQ**
4. Font settings (right panel):
   - **Font:** Inter, SF Pro Display, or Poppins
   - **Weight:** Black (900) or Extra Bold (800)
   - **Size:** 400-500 px
   - **Color:** White `#FFFFFF`
   - **Alignment:** Center
5. Position text in center:
   - Select text
   - Right panel → **Align horizontal centers**
   - Right panel → **Align vertical centers**

### Step 4: Add Text Effects (EcoFlow Style)
1. Select "IQ" text
2. Add **Drop Shadow** (Effects → + → Drop Shadow):
   - X: 0, Y: 8
   - Blur: 24
   - Color: Black `#000000` at 40% opacity
3. Optional: Add subtle **Inner Shadow**:
   - X: 0, Y: -2
   - Blur: 4
   - Color: Black at 20% opacity
4. Optional: Add **stroke** (bold outline):
   - Stroke: 2-4 px
   - Color: White `#FFFFFF` at 20% opacity
   - Position: Outside

### Step 5: Fine-Tune Layout
1. Adjust letter spacing (tracking):
   - Select text → Right panel → Letter spacing: -2% to -5%
2. Ensure text is perfectly centered
3. Check contrast - text should be clearly readable
4. If text gets lost in gradient, add subtle backdrop:
   - Draw rounded rectangle behind text
   - Fill: Black `#000000` at 10-20% opacity
   - Blur: 40 px

### Step 6: Export
1. Select the **"App Icon"** frame (not individual layers)
2. Right panel → **Export** section
3. Click **+** to add export settings:
   - Format: **PNG**
   - Size: **1x** (1024×1024)
   - Name: `inboxiq-icon-mesh-iq.png`
4. Click **Export App Icon**
5. Save to: `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/assets/`

### Step 7: Add to Xcode
1. Open Xcode project: `/projects/inboxiq/ios/InboxIQ/InboxIQ.xcodeproj`
2. Navigate to **Assets.xcassets** → **AppIcon**
3. Drag exported PNG to **1024×1024** slot
4. Xcode will auto-generate all sizes
5. Build and run to verify

## Design Variations to Try

**Variation 1: Gradient Text**
- Instead of solid white, make "IQ" text gradient:
  - Top: Bright yellow `#FBBF24`
  - Bottom: Gold `#F59E0B`
- Adds dimension and energy

**Variation 2: Outlined Text**
- Keep background same
- Make "IQ" text outlined (no fill):
  - Stroke: 12-16 px
  - Color: White `#FFFFFF`
- Modern, bold look

**Variation 3: Subtle Glow**
- Add outer glow to text:
  - Effects → Outer Glow
  - Blur: 32 px
  - Color: Cyan `#06B6D4` or Purple `#8B5CF6`
  - Opacity: 60%
- Creates AI-powered feel

## EcoFlow Style Reference

**EcoFlow "EF" characteristics:**
- **Very bold, thick letters** (Black/Extra Bold weight)
- **Sans-serif modern font** (geometric, clean)
- **Tight letter spacing** (letters close together)
- **High contrast** (bold letters on vibrant background)
- **Simple and recognizable** (no extra decorations)

**Apply to InboxIQ "IQ":**
- Use same bold approach
- Keep it clean and simple
- Let the mesh gradient add visual interest
- Text should be the hero element

## Colors Used
- Purple: `#8B5CF6`
- Blue: `#3B82F6`
- Pink: `#EC4899`
- Orange: `#F97316`
- Text: White `#FFFFFF`
- Shadow: Black `#000000`

## Final Deliverable
- **File:** `inboxiq-icon-mesh-iq.png`
- **Size:** 1024×1024 px
- **Format:** PNG with transparency
- **Location:** `/projects/inboxiq/assets/`

## Estimated Time
**15-20 minutes** (mesh gradient + text styling)

---

**Note:** If you need help adjusting any aspect (text size, gradient colors, effects), let me know and I can provide more specific guidance.
