// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

// Import ECharts
import * as echarts from 'echarts'

// Make echarts available globally
window.echarts = echarts;
