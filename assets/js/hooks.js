import theme from "./theme"
import WebGLFluid from 'webgl-fluid'

let hooks = {};

hooks.RegisterSlash = {
  mounted() {
    const el = this.el
    document.addEventListener("keyup", e => {
      if (e.key !== "/" || e.ctrlKey || e.metaKey) return;
      if (/^(?:input|textarea|select|button)$/i.test(e.target.tagName)) return;

      e.preventDefault();
      el.focus()
    });
  }
}

hooks.HandleScroll = {
  mounted() {
    this.handleEvent("scroll", ({ to }) => {
      if (!to) return
      const el = document.querySelector(to)
      if(el) {
        el.scrollIntoView({ behavior: "smooth" })
        location.hash = to
      } else {
        console.warn(`scroll event did not find ${to} to scroll to`)
      }
    })
  }
}

hooks.AutoScroll = {
  mounted() { this.toBottom() },
  updated() { this.toBottom() },
  toBottom() { this.el.scrollTop = this.el.scrollHeight }
}

hooks.MaskFlags = {
  mounted() {
    this.el.addEventListener("input", _event => {
      let masked = this.el.value
      masked = masked.replace(/[^Ufimsux]+/g, "");
      masked = masked.split('').filter((item, i, ar) => ar.indexOf(item) === i).join('');
      this.el.value = masked;
    });
  }
}

hooks.WaterRipple = {
  mounted() {
    const canvas = this.el.querySelector("#nav-fluid")
    if (!canvas) return

    // Pin the canvas to an explicit pixel size so its client size can't feed back off
    // the WebGL backing store (which otherwise runs away to millions of px). Skip while
    // the bar has no size (layout not ready) so the sim never inits a 0-size framebuffer.
    const sizeCanvas = () => {
      const rect = this.el.getBoundingClientRect()
      if (rect.width < 1 || rect.height < 1) return false
      canvas.style.width = Math.round(rect.width) + "px"
      canvas.style.height = Math.round(rect.height) + "px"
      return true
    }

    const start = () => {
      if (!sizeCanvas()) {
        this.raf = requestAnimationFrame(start) // wait until the bar has a real size
        return
      }

      this.ro = new ResizeObserver(sizeCanvas)
      this.ro.observe(this.el)

      WebGLFluid(canvas, {
        TRIGGER: "hover",            // splat on cursor move, no click needed
        TRANSPARENT: true,           // show the dark nav through the canvas
        // The bar is ~21:1; the lib sizes textures as resolution*aspect, so the default
        // DYE_RESOLUTION (1024) blows past GL_MAX_TEXTURE_SIZE and the FBO fails. Keep low.
        SIM_RESOLUTION: 128,
        DYE_RESOLUTION: 256,
        COLORFUL: false,
        SPLAT_COLOR: { r: 0.6, g: 0.15, b: 1.0 }, // bright Elixir purple dye
        SPLAT_RADIUS: 0.25,          // larger, softer blob around the cursor
        SPLAT_FORCE: 8000,
        DENSITY_DISSIPATION: 1.3,    // dye lingers to show the flow, then settles
        VELOCITY_DISSIPATION: 0.4,   // motion keeps propagating & rippling for a while
        PRESSURE: 1.0,               // incompressible → strong wave-like propagation
        PRESSURE_ITERATIONS: 32,
        CURL: 65,                    // heavy vorticity → lots of swirling, watery tendrils
        SHADING: true,               // liquid-surface highlights/shadows
        BLOOM: false,                // bloom spread the glow across the whole bar
        SUNRAYS: false,
        AUTO: false,
      })

      // The canvas is pointer-events:none so nav links stay clickable — forward
      // the header's hover position to the canvas as a synthetic mousemove.
      this.onMove = (e) => {
        canvas.dispatchEvent(new MouseEvent("mousemove", { clientX: e.clientX, clientY: e.clientY }))
      }
      this.el.addEventListener("pointermove", this.onMove)
    }

    start()
  },
  destroyed() {
    if (this.raf) cancelAnimationFrame(this.raf)
    if (this.onMove) this.el.removeEventListener("pointermove", this.onMove)
    if (this.ro) this.ro.disconnect()
  }
}

hooks.ClipboardCopy = {
  mounted() {
    const el = this.el;
    el.addEventListener("click", (_e) => {
      const targetEl = document.getElementById(el.dataset.target);
      targetEl.select();
      document.execCommand("copy");
      const previousText = el.innerText;
      el.innerText = "Copied!"
      targetEl.selectionStart = targetEl.selectionEnd;
      setTimeout(() => el.innerText = previousText, 5000)
    });
  }
}

hooks.ThemeChooser = {
  mounted() {
    theme.init()
  }
}

hooks.PreviewImage = {
  mounted() {
    this.handleEvent("preview", ({ data }) => {
      this.el.src = `data:image/png;base64,${data}`
    })
  }
}

export default hooks;
