var w = 1000, h = 500;
var radius = h / 5, innerRadius = radius / 2;
var svg_div = d3.select("body")
                .append("div")
                .attr("align", "center")
                .attr("style", "overflow-y: auto; overflow-x: auto;");
var svg = svg_div.append("svg")
                 .attr("height", h)
                 .attr("width", w);

var cleared = [false, false];
function clearInput(i) {
  if (cleared[i]) return;
  cleared[i] = true;
  if (i == 0) d3.select("#from").attr("value", "");
  else d3.select("#to").attr("value", "");
}

function validateDate(i) {
  var datestr;
  if (i == 0) datestr = d3.select("#from").property("value");
  else datestr = d3.select("#to").property("value");
  datestr = datestr.trim();
  var vals = datestr.split("/");
  if (vals.length != 3) {
    alert("Please enter a valid date.");
    return;
  }
}

var showTasks = true;
function toggleMode() {
  showTasks = !showTasks;
  processData();
}

var showSecsOnly = false;
function toggleShow() {
  showSecsOnly = !showSecsOnly;
  setMouseoverText();
}

function leadingZero(i) {
  return (i < 10) ? "0" + i : i;
}

// adapted from http://stackoverflow.com/questions/4522213/can-someone-explain-this-javascript-real-time-clock-to-me
function currentTimeStr() {
  var today = new Date();
  var mo = leadingZero(today.getMonth()+1),
      d = leadingZero(today.getDate()),
      y = today.getFullYear(),
      h = leadingZero(today.getHours()),
      mn = leadingZero(today.getMinutes()),
      s = leadingZero(today.getSeconds());
  return mo + "/" + d + "/" + y + " " + h + ":" + mn + ":" + s;
}

function startTime() {
  document.getElementById('time').innerHTML = currentTimeStr();
  /*setTimeout(function() {
      startTime()
  }, 250);*/ // right now, we only load the data once!
}
startTime();

var re = new RegExp('(?<!\\\\),');
var fulldata;
// avoid caching
d3.text("Statistics.txt?" + Math.floor(Math.random() * 9999), function(d) {
  var lines = d.split("\n");
  var index = 0; // skip first line
  var firstSess = true;
  var sessions = [], curSessData = [];
  var curSessDict = {};
  var curStart, curEnd;
  while (index++ < lines.length - 1) { // Skip first line
    var line = lines[index];
    if (line.trim() === "") continue;
    var splitLine = line.split(" ");
    var firstWord = splitLine[0];
    if (firstWord === "Session") {
      if (firstSess) {
        firstSess = false;
      }
      else {
        sessions.push(curSessData);
      }
      curSessData = [];
      var sessInfo = line.split(",");
      curSessData.push(sessInfo[0].substring(8));
      curSessData.push(sessInfo[1]);
    }
    else if (firstWord === "Started") {
      curStart = Date.parse(splitLine[2] + splitLine[3]);
    }
    else if (firstWord === "Stopped") {
      curEnd = Date.parse(splitLine[2] + splitLine[3]);
    }
    else {
      var activity = line.split(re);
      var firstActWord = activity[0].split(" ")[0];
      var actType;
      if (firstActWord === "Task:") {
        actType = 0;
      }
      else if (firstActWord === "Break") {
        actType = 1;
      }
      else actType = 2;
      if (activity.length < 3) activity.push(currentTimeStr());
      var startTime = Date.parse(activity[1]), endTime = Date.parse(activity[2]);
      var duration = (endTime - startTime)/1000;
      activity.push(actType);
      activity.push(duration);
      curSessData.push(activity);
    }
  }
  sessions.push(curSessData);
  fulldata = sessions;
  processData();
  return d;
});

// From https://stackoverflow.com/a/5624139
function hexToRgb(hex) {
  // Expand shorthand form (e.g. "03F") to full form (e.g. "0033FF")
  var shorthandRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i;
  hex = hex.replace(shorthandRegex, function(m, r, g, b) {
    return r + r + g + g + b + b;
  });

  var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result ? {
    r: parseInt(result[1], 16),
    g: parseInt(result[2], 16),
    b: parseInt(result[3], 16)
  } : null;
}
// Adapted from https://stackoverflow.com/a/5624139
function rgbToHex(d) {
  var r = d['r'], g = d['g'], b = d['b'];
  return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
}
var lf = 1.2;

// Thanks to https://stackoverflow.com/a/46774740/2258552
const toTitleCase = (str) => {
  const articles = ['a', 'an', 'the'];
  const conjunctions = ['for', 'and', 'nor', 'but', 'or', 'yet', 'so'];
  const prepositions = [
    'with', 'at', 'from', 'into','upon', 'of', 'to', 'in', 'for',
    'on', 'by', 'like', 'over', 'plus', 'but', 'up', 'down', 'off', 'near'
  ];

  // handle escaped commas as well
  const replaceCharsWithSpace = (str) => str.replace('\\,', ',').replace(/(\s\s+)/gi, ' ');
  const capitalizeFirstLetter = (str) => str.charAt(0).toUpperCase() + str.substr(1);
  const normalizeStr = (str) => str.toLowerCase().trim();
  const shouldCapitalize = (word, fullWordList, posWithinStr) => {
    if ((posWithinStr == 0) || (posWithinStr == fullWordList.length - 1)) {
      return true;
    }

    return !(articles.includes(word) || conjunctions.includes(word) || prepositions.includes(word));
  }

  str = replaceCharsWithSpace(str);
  str = normalizeStr(str);

  let words = str.split(' ');
  if (words.length <= 2) { // Strings less than 3 words long should always have first words capitalized
    words = words.map(w => capitalizeFirstLetter(w));
  }
  else {
    for (let i = 0; i < words.length; i++) {
      words[i] = (shouldCapitalize(words[i], words, i) ? capitalizeFirstLetter(words[i], words, i) : words[i]);
    }
  }

  return words.join(' ');
}

var names_s = ["d", "h", "m", "s"], names_l = [" Day", " Hour", " Minute", " Second"];
function timeString(num_secs, condensed=false) {
  var nums = [0, 0, 0, 0];
  var names = condensed ? names_s : names_l;
  nums[0] = Math.floor(num_secs / 86400);
  nums[1] = Math.floor((num_secs % 86400) / 3600);
  nums[2] = Math.floor((num_secs % 3600) / 60);
  nums[3] = num_secs % 60;
  var retval = "";
  for (var i = 0; i < 4; i++) {
    if (nums[i] != 0) {
      if (retval !== "") retval += ", ";
      retval += nums[i] + names[i];
      if (!condensed && nums[i] > 1) retval += "s";
    }
  }
  if (retval === "") retval = condensed ? "0s" : "0 Seconds";
  return retval;
}

var workInfo = {}, workTotals1 = [0, 0, 0], workTotals2 = [], tasks = [], sessLength = 0, loaded = false, colors;
function processData() { // TODO: Put d3 visualizations in separate file for faster loading (load basic ones first?)
  if (!loaded) {
    for (var i = 0; i < fulldata.length; i++) {
      var session = fulldata[i];
      for (var j = 2; j < session.length; j++) {
        workTotals1[session[j][3]] += session[j][4];
        var activityName = toTitleCase(session[j][0]);
        if (activityName in workInfo)
          workInfo[activityName] += session[j][4];
        else
          workInfo[activityName] = session[j][4];
        sessLength += session[j][4];
      }
    }
    for (var key in workInfo) {
      if (key === "Break" || key === "Wasted") continue;
      tasks.push(key);
      workTotals2.push(workInfo[key]);
    }
    tasks.push("Break");
    tasks.push("Wasted");
    workTotals2.push(workTotals1[1]);
    workTotals2.push(workTotals1[2]);
    loaded = true;
    d3.select("#tot_time").node().innerHTML = "Total Time: " + timeString(sessLength);
    d3.select("#tot_work_time").node().innerHTML = "Total Time Working: " + timeString(workTotals1[0]);
    d3.select("#tot_waste_time").node().innerHTML = "Total Time Wasted: " + timeString(workTotals1[2]);
  }

  var workData = showTasks ? workTotals2 : workTotals1;
  colors = showTasks ? d3.schemeCategory20 : d3.schemeCategory10;
  var categories = showTasks ? tasks : ["Work Time", "Break Time", "Wasted Time"];
  svg.selectAll("g").remove();
  var g = svg.append("g").attr("transform", "translate(" + w/4 + ", " + h/2 + ")");
  var pie = d3.pie().sort(null);
  var arc = g.selectAll(".arc")
             .data(pie(workData))
             .enter()
             .append("g")
             .attr("class", "arc")
             .attr("id", function(d,i){ return "arc_" + i; });

  var path = d3.arc().outerRadius(radius).innerRadius(innerRadius);
  var label = d3.arc().outerRadius(radius*1.5).innerRadius(radius*1.5);
  arc.append("path")
     .attr("d", path)
     .attr("fill", function(d,i){ return colors[i]; });

  setMouseoverText();
  g.selectAll(".arc").on("mouseout", function(d,i){
    d3.select(this)
      .select("text")
      .remove();
    d3.select(this).selectAll("path").attr("fill", colors[i]);
  });
  var legendSqSize = 20, legendSpacing = 4;
  var legend = svg.selectAll('.legend')
                  .data(categories)
                  .enter()
                  .append('g')
                  .attr('class', 'legend')
                  .attr('transform', function(d,i){
                    var height = legendSqSize + legendSpacing;
                    var offset = categories.length * height / 2;
                    var vert = i * height - offset + h/2;
                    var horz = w * 4/5;
                    return 'translate(' + horz + ',' + vert + ')';
                  });
  legend.append('rect')
        .attr('width', legendSqSize)
        .attr('height', legendSqSize)
        .style('fill', function(d,i){ return colors[i]; })
        .style('stroke', function(d,i){ return colors[i]; });
  var textOffsetX = 4, textOffsetY = 5; // adding textOffsetY = 5 seems to center text vertically w.r.t. legend square
  legend.append('text')
        .attr('x', legendSqSize + textOffsetX)
        .attr('y', legendSqSize / 2 + textOffsetY)
        .attr("fill", "black")
        .text(function(d){ return d; });
}

function setMouseoverText() {
  var g = svg.selectAll("g");
  var label = d3.arc().outerRadius(radius*1.5).innerRadius(radius*1.5);
  g.selectAll(".arc").on("mouseover", function(d,i){
    this.parentNode.appendChild(this); // move to end, so that text does not get obscured (due to order in which SVG elements render)
    var arc_index = parseInt(d3.select(this).attr("id").substring(4));
    var cur_rgb = hexToRgb(colors[arc_index]);
    for (var key in cur_rgb) {
      cur_rgb[key] = Math.min(255, Math.round(cur_rgb[key] * lf));
    }
    d3.select(this).selectAll("path").attr("fill", rgbToHex(cur_rgb));
    d3.select(this).append("text")
                   .attr("transform", function(d){
                      var cent = label.centroid(d);
                      cent[0] -= 15;
                      cent[1] -= 5;
                      return "translate(" + cent + ")"; })
                   .attr("fill", "black")
                   .attr("style", "pointer-events: none; user-select: none;")
                   .text(function(d){ return (showSecsOnly ? d.data + "s" : timeString(d.data, true)) + " (" + (d.data/sessLength*100).toFixed(1) + "%)"; });
  });
}
