var w = 1000, div_h = 504, div_h_true = div_h + 4; // offset of 4 to avoid needless scrollbar in svg height=504 case
var radius = w / 10, innerRadius = radius / 2;
var svg_div = d3.select("#svg_div");
svg_div.attr("style", "overflow-y:auto; overflow-x:auto; height:" + div_h_true + "px");
var svg = svg_div.append("svg")
                 .attr("width", w);

var lastDateInput = ["", ""], lastDateInputOrig;
var lastDateInputN = [-1, -1];
function validateDate(i) {
  var selectedId = (i == 0) ? "#from" : "#to", datestr = d3.select(selectedId).property("value").trim();
  var date = timeStr(new Date(Date.parse(datestr)), fullYear=false, dateOnly=true);
  if (date !== datestr) {
    alert("Please enter a valid date in mm/dd/yy format.");
    d3.select(selectedId).property("value", lastDateInput[i]);
    return;
  }
  if (lastDateInput[i] === datestr) return; // no change
  lastDateInput[i] = datestr;
  lastDateInputN[0] = Date.parse(lastDateInput[0]);
  lastDateInputN[1] = Date.parse(lastDateInput[1]); // update both, for simplicity
  if (lastDateInputN[1] < lastDateInputN[0]) {
    if (i == 0)
      alert("Start date should not be after end date!");
    else
      alert("End date should not be before start date!");
    lastDateInput[i] = lastDateInput[1-i];
    d3.select(selectedId).property("value", lastDateInput[i]);
    lastDateInputN[i] = lastDateInputN[1-i];
  }
  loaded = false;
  processData();
}
d3.select("#from").on("change", function(){ validateDate(0); });
d3.select("#to").on("change", function(){ validateDate(1); });

var workInfo, workTotals1, workTotals2, tasks, categoryNames, sessLength, loaded = false, colors, clicked, deletedSet = new Set();
var showTasks = true;
function toggleMode() {
  showTasks = !showTasks;
  processData();
}
d3.select("#show_tasks").on("click", toggleMode);

var showSecsOnly = false;
function toggleShowSecs() {
  showSecsOnly = !showSecsOnly;
}
d3.select("#show_secs").on("click", toggleShowSecs);

var tot_times = [0, 0, 0];
var showDays = false;
function toggleShowDays() {
  showDays = !showDays;
  for (let i = 0; i < 3; i++)
    d3.select("#span_" + i).text(timeString(tot_times[i], condensed=false, days=showDays));
}
d3.selectAll(".time_div").selectAll("span").on("click", toggleShowDays);
d3.selectAll(".time_div").append("span").attr("class", "tot_time_span").attr("id", function(d, i){ return "span_" + i; });

function reset(dateonly=false) {
  lastDateInput = lastDateInputOrig.slice();
  lastDateInputN = [-1, -1];
  d3.select("#from").property("value", lastDateInput[0]);
  d3.select("#to").property("value", lastDateInput[1]);
  if (!dateonly) {
    showSecsOnly = false;
    showDays = false;
    deletedSet = new Set();
  }
  loaded = false;
  processData();
}
d3.select("#reset_button").on("click", reset);

function setWeek(offset=0) {
  var loadCopy = new Date(loadDate.getTime());
  var day = loadCopy.getDay();
  loadCopy.setHours(0); loadCopy.setMinutes(0); loadCopy.setSeconds(0); loadCopy.setMilliseconds(0);
  var weekStart = new Date(loadCopy.getTime()), weekEnd = new Date(loadCopy.getTime());
  weekStart.setDate(loadCopy.getDate() - day - offset);
  weekEnd.setDate(loadCopy.getDate() + (6-day) - offset);
  var fromStr = timeStr(weekStart, false, true), toStr = timeStr(weekEnd, false, true);
  if (lastDateInput[0] === fromStr && lastDateInput[1] === toStr) return; // no change
  lastDateInput = [fromStr, toStr];
  lastDateInputN = [weekStart.valueOf(), weekEnd.valueOf()];
  d3.select("#from").property("value", lastDateInput[0]);
  d3.select("#to").property("value", lastDateInput[1]);
  loaded = false;
  processData();
}
d3.select("#this_week_button").on("click", setWeek);
d3.select("#last_week_button").on("click", function(){ setWeek(7); });
d3.select("#total_button").on("click", function(){ reset(dateonly=true); });

function leadingZero(i) {
  return (i < 10) ? "0" + i : i;
}

// adapted from http://stackoverflow.com/questions/4522213/can-someone-explain-this-javascript-real-time-clock-to-me
function timeStr(dateObj, fullYear=true, dateOnly=false) {
  var mo = leadingZero(dateObj.getMonth()+1),
      d = leadingZero(dateObj.getDate()),
      y = dateObj.getFullYear(),
      h = leadingZero(dateObj.getHours()),
      mn = leadingZero(dateObj.getMinutes()),
      s = leadingZero(dateObj.getSeconds());
  if (!fullYear) y = String(y).substring(2);
  return mo + "/" + d + "/" + y + ((dateOnly) ? "" : (" " + h + ":" + mn + ":" + s));
}

var loadDate = null;
function currentTimeStr(fullYear=true) {
  if (loadDate == null)
    loadDate = new Date();
  return timeStr(loadDate, fullYear);
}

function startTime() {
  d3.select("#time").text(currentTimeStr());
}
startTime();

var re = new RegExp("(?<!\\\\),");
var fulldata;
// avoid caching
d3.text("Statistics.txt?" + Math.floor(Math.random() * 9999), function(d) {
  var lines = d.split("\n");
  var index = 0; // skip first line
  var firstSess = true;
  var sessions = [], curSessData = [], bad_lines = [];
  var curSessDict = {};
  var curStart, curEnd;
  while (index++ < lines.length - 1) { // Skip first line
    var line = lines[index];
    if (line.trim() === "" || line[0] === "#") continue; // skip comments and blank lines
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
      if (activity.length < 3) activity.push(currentTimeStr(false));
      var startTime = Date.parse(activity[1]), endTime = Date.parse(activity[2]);
      var duration = (endTime - startTime)/1000;
      activity.push(actType);
      activity.push(duration);
      if (isNaN(duration)) {
        var alertstr = 'Malformed line in Statistics.txt: "' + line + '" [line ' + (index+1) + ']';
        bad_lines.push(alertstr);
        console.log(alertstr);
      }
      else
        curSessData.push(activity);
    }
  }
  if (bad_lines.length > 0)
    alert(bad_lines.join("\n"));
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
  var r = d["r"], g = d["g"], b = d["b"];
  return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
}

function hoverizeColor(c, lf=1.2, la=5) {
  var cur_rgb = hexToRgb(c);
  for (var key in cur_rgb) {
    cur_rgb[key] = Math.max(Math.min(255, Math.round(cur_rgb[key] * lf + la)), 0);
  }
  return rgbToHex(cur_rgb);
}

// Thanks to https://stackoverflow.com/a/46774740/2258552
const toTitleCase = (str) => {
  const articles = ["a", "an", "the"];
  const conjunctions = ["for", "and", "nor", "but", "or", "yet", "so"];
  const prepositions = [
    "with", "at", "from", "into","upon", "of", "to", "in", "for",
    "on", "by", "like", "over", "plus", "but", "up", "down", "off", "near"
  ];

  // consolidate whitespace and handle escaped commas
  const replaceCharsWithSpace = (str) => str.replace("\\,", ",").replace(/(\s\s+)/gi, " ");
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

  let words = str.split(" ");
  if (words.length <= 2) { // Strings less than 3 words long should always have first words capitalized
    words = words.map(w => capitalizeFirstLetter(w));
  }
  else {
    for (let i = 0; i < words.length; i++) {
      words[i] = (shouldCapitalize(words[i], words, i) ? capitalizeFirstLetter(words[i], words, i) : words[i]);
    }
  }

  return words.join(" ");
}

var names_s = ["d", "h", "m", "s"], names_l = [" Day", " Hour", " Minute", " Second"];
function timeString(num_secs, condensed=true, days=false) {
  var nums = [0, 0, 0, 0];
  var names = condensed ? names_s : names_l;
  nums[0] = days ? Math.floor(num_secs / 86400) : 0;
  nums[1] = Math.floor((days ? num_secs % 86400 : num_secs) / 3600);
  nums[2] = Math.floor((num_secs % 3600) / 60);
  nums[3] = num_secs % 60;
  var retval = "";
  for (let i = 0; i < 4; i++) {
    if (nums[i] != 0) {
      if (retval !== "") retval += ", ";
      retval += nums[i] + names[i];
      if (!condensed && nums[i] > 1) retval += "s";
    }
  }
  if (retval === "") retval = condensed ? "0s" : "0 Seconds";
  return retval;
}

function processData() { // TODO: Put d3 visualizations in separate file for faster loading (load basic ones first?)
  if (!loaded) {
    workInfo = {};
    workTotals1 = [0, 0, 0];
    workTotals2 = [];
    tasks = [];
    sessLength = 0;
    if (fulldata.length > 0 && lastDateInput[0] === "") {
      lastDateInput[0] = fulldata[0][2][1].trim().split(" ")[0];
      d3.select("#from").property("value", lastDateInput[0]);
      var lastSess = fulldata[fulldata.length-1];
      var lastTask = lastSess[lastSess.length-1];
      lastDateInput[1] = lastTask[2].trim().split(" ")[0];
      d3.select("#to").property("value", lastDateInput[1]);
      lastDateInputOrig = lastDateInput.slice();
    }
    var shouldBreak = false;
    for (let i = 0; i < fulldata.length; i++) {
      var session = fulldata[i];
      for (let j = 2; j < session.length; j++) {
        var activity = session[j].slice();
        var activityName = toTitleCase(activity[0]);
        if (deletedSet.has(activityName)) continue;
        if (lastDateInputN[0] != -1 || lastDateInputN[1] != -1) {
          var startDay = Date.parse(activity[1].trim().split(" ")[0]),
              endDay = Date.parse(activity[2].trim().split(" ")[0]);
          if (endDay < lastDateInputN[0]) // activity ends before the desired start date
            continue;
          if (startDay > lastDateInputN[1]) { // activity starts after the desired end date (and so all subsequent ones do too)
            shouldBreak = true;
            break;
          }
          if (startDay < lastDateInputN[0]) // activity starts before the desired start date, but ends during/after it
            activity[4] -= (lastDateInputN[0] - Date.parse(activity[1])) / 1000; // difference between start of date range and beginning of activity
          if (endDay > lastDateInputN[1]) // activity ends after desired end date, but starts during/before it
            activity[4] -= (Date.parse(activity[2]) - (lastDateInputN[1] + 86400000)) / 1000; // difference between ending of activity and end of date range
        }
        workTotals1[activity[3]] += activity[4];
        if (activityName in workInfo)
          workInfo[activityName] += activity[4];
        else
          workInfo[activityName] = activity[4];
        sessLength += activity[4];
      }
      if (shouldBreak) break;
    }
    for (var key in workInfo) {
      if (key === "Break" || key === "Wasted") continue;
      tasks.push([key, workInfo[key]]);
      workTotals2.push(workInfo[key]);
    }
    tasks.push(["Break", workTotals1[1]]);
    tasks.push(["Wasted", workTotals1[2]]);
    workTotals2.push(workTotals1[1]);
    workTotals2.push(workTotals1[2]);
    loaded = true;
    tot_times = [sessLength, workTotals1[0], workTotals1[2]];
    for (let i = 0; i < 3; i++)
      d3.select("#span_" + i).text(timeString(tot_times[i], condensed=false, days=showDays));
  }

  var workData = showTasks ? workTotals2 : workTotals1;
  colors = showTasks ? d3.schemeCategory20 : d3.schemeCategory10;
  var categories = showTasks ? tasks : ["Work Time", "Break Time", "Wasted Time"].map(function(s,i){ return [s, workTotals1[i]]; });
  if (showTasks) {
    for (let i = 20; i < categories.length; i++) // add extra colors as necessary
      colors.push(hoverizeColor(colors[i-20], lf=0.7, la=-7.5));
  }

  var legendSqSize = Math.min(20, Math.max(16, 41 - categories.length)), legendSpacing = legendSqSize / 5, height = legendSqSize + legendSpacing;
  var svg_h = Math.max(div_h, height * categories.length);
  svg.attr("height", svg_h);
  svg_div.node().scrollTop = (svg_h - div_h) / 2;

  svg.selectAll("g").remove();
  var g = svg.append("g").attr("transform", "translate(" + w/4 + ", " + svg_h/2 + ")");
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

  setPiechartMouseoverText();

  var legendTextOffsetX = 4, legendTextOffsetY = 5; // adding legendTextOffsetY = 5 seems to center text vertically w.r.t. legend square

  categoryNames = [];
  for (let i = 0; i < categories.length; i++) categoryNames.push(categories[i][0]);
  clicked = new Array(categoryNames.length).fill(false);

  var textWidths = computeTextWidths(categoryNames), maxWidth = Math.max(...textWidths) + legendTextOffsetX + legendSqSize + 1;

  var legend = svg.selectAll(".legend")
                  .data(categories)
                  .enter()
                  .append("g")
                  .attr("class", "legend")
                  .attr("transform", function(d,i){
                    var offset = categories.length * height / 2;
                    var vert = i * height - offset + svg_h/2;
                    var horz = Math.min(w * 4/5, w - maxWidth);
                    return "translate(" + horz + "," + vert + ")";
                  });
  legend.append("rect")
        .attr("width", legendSqSize)
        .attr("height", legendSqSize)
        .style("fill", function(d,i){ return colors[i]; })
        .style("stroke", function(d,i){ return colors[i]; })
        .style("stroke-width", 1)
        .on("mouseover", function(d,i){
          d3.select(this).style("fill", hoverizeColor(colors[i]));
          d3.select(this.parentNode).append("text")
            .attr("fill", "black")
            .attr("style", "pointer-events: none; user-select: none;")
            .attr("class", "hovertext")
            .text(function(d){ return (showSecsOnly ? d[1] + "s" : timeString(d[1])) + " (" + (d[1]/sessLength*100).toFixed(1) + "%)"; })
            .attr("transform", function(d){ return "translate(-" + (this.getComputedTextLength() + legendTextOffsetX) + ", " + (legendSqSize / 2 + legendTextOffsetY) + ")"; });
        })
        .on("mouseout", function(d,i){
          d3.select(this.parentNode).selectAll(".hovertext").remove();
          d3.select(this).style("fill", colors[i]);
        });
  legend.append("text")
        .attr("x", legendSqSize + legendTextOffsetX)
        .attr("y", legendSqSize / 2 + legendTextOffsetY)
        .attr("fill", "black")
        .text(function(d){ return d[0]; });
  d3.select("#reset_button").attr("style", "");
}

// Doesn't seem to be a significantly better way to do it; see https://stackoverflow.com/questions/29031659/calculate-width-of-text-before-drawing-the-text
function computeTextWidths(input_text) {
  var textWidths = [];
  var g = svg.append("g")
    .attr("id", "placeholder")
    .selectAll(".placeholder")
    .data(input_text)
    .enter()
    .append("text")
    .text(function(d) { return d; })
    .each(function(d,i) {
        textWidths.push(this.getComputedTextLength());
        this.remove();
    });
  svg.select("#placeholder").remove();
  return textWidths;
}

// Resets clicks of all indices except the specified one to ignore
function resetClicks(ignore) {
  for (let i = 0; i < clicked.length; i++) { if (i == ignore) continue; clicked[i] = false; }
}
function setPiechartMouseoverText() {
  var g = svg.selectAll("g");
  var label = d3.arc().outerRadius(radius*1.5).innerRadius(radius*1.5);
  var arcTextOffsetX = 25, arcTextOffsetY = 5;
  var addfun = function(d,i,elem,isClick){
    elem.parentNode.appendChild(elem); // move to end, so that text does not get obscured (due to order in which SVG elements render)
    var arc_index = parseInt(d3.select(elem).attr("id").substring(4));
    d3.select(elem).selectAll("path").attr("fill", hoverizeColor(colors[arc_index]));
    if (!clicked[arc_index]) {
      d3.select(elem).append("text")
                     .attr("transform", function(d){
                        var cent = label.centroid(d);
                        cent[0] -= arcTextOffsetX;
                        cent[1] -= arcTextOffsetY;
                        return "translate(" + cent + ")"; })
                     .attr("fill", "black")
                     .attr("style", "pointer-events: none; user-select: none;")
                     .attr("class", isClick ? "click" : "mouseover")
                     .text(function(d){ return (showSecsOnly ? d.data + "s" : timeString(d.data)) + " (" + (d.data/sessLength*100).toFixed(1) + "%)"; });
    }
  };
  var delfun = function(d,i,elem,isClick){
    d3.select(elem)
      .selectAll("." + (isClick ? "click" : "mouseover"))
      .remove();
    if (!isClick) d3.select(elem).selectAll("path").attr("fill", colors[i]);
  };
  g.selectAll(".arc").on("mouseover", function(d,i) { addfun(d,i,this,false); });
  g.selectAll(".arc").on("mouseout", function(d,i) { delfun(d,i,this,false); });
  g.selectAll(".arc").on("click", function(d,i){
    var arc_index = parseInt(d3.select(this).attr("id").substring(4));
    if (!d3.event.shiftKey) {
      resetClicks(arc_index);
      svg.selectAll("g").selectAll(".arc").selectAll("text").remove();
    }
    if (clicked[arc_index]) {
      delfun(d, i, this, true);
      clicked[arc_index] = false;
    }
    else {
      addfun(d, i, this, true);
      clicked[arc_index] = true;
    }
  });
  d3.select("body").on("click", function(){
    if (d3.event.target.tagName !== "path") {
      resetClicks(-1);
      svg.selectAll("g").selectAll(".arc").selectAll("text").remove();
    }
  });
}

d3.select("body").on("keydown", function(){
  if (d3.event.keyCode == 8) {
    var anyClicked = false;
    for (let i = 0; i < clicked.length; i++) {
      anyClicked = anyClicked || clicked[i];
      if (clicked[i]) deletedSet.add(categoryNames[i]);
    }
    if (anyClicked) {
      if (!showTasks) { // Intentionally do not delete tasks directly in 'basic' mode
        resetClicks(-1);
        svg.selectAll("g").selectAll(".arc").selectAll("text").remove();
      }
      else {
        loaded = false;
        processData();
      }
    }
  }
});
