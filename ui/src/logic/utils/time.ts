export const descriptiveTime = ({
  hours,
  minutes,
  days,
}: {
  hours: number;
  minutes: number;
  days: number;
}) => {
  let descriptiveString = "";
  if (days === 1) {
    descriptiveString = `${days} day`;
  } else if (days > 0) {
    descriptiveString = `${days} days`;
  } else {
    // there are 0 days left
    if (hours === 1) {
      descriptiveString = `${hours} hour`;
    } else if (hours > 0) {
      descriptiveString = `${hours} hours`;
    } else {
      // there are 0 days and 0 hours, only minutes left
      if (minutes === 1) {
        descriptiveString = `${minutes} minute`;
      } else if (minutes > 0) {
        descriptiveString = `${minutes} minutes`;
      } else {
        descriptiveString = `less than a minute`;
      }
    }
  }
  return descriptiveString;
};

export const descriptiveTimeString = (start: number, end: number) => {
  let now = new Date().getTime();
  start = start * 1000;
  end = end * 1000;
  if (now < start) {
    const nowStartDiff = dateDiff(now, start);
    return `Starts in ${descriptiveTime(nowStartDiff)}`;
  } else if (now > start && now < end) {
    const nowEndDiff = dateDiff(now, end);
    return `${descriptiveTime(nowEndDiff)} left`;
  } else {
    return "Closed";
  }
};

export const dateDiff = (start: number, end: number) => {
  var timeDiff = end - start;
  let dayDiff = Math.floor(timeDiff / 1000 / 60 / 60 / 24);
  var minDiff = Math.floor(timeDiff / 60 / 1000);
  var hourDiff = timeDiff / 3600 / 1000;
  var diffObj = {
    hours: 0,
    minutes: 0,
    days: 0,
  };
  diffObj.days = dayDiff;
  diffObj.hours = Math.floor(hourDiff);
  diffObj.minutes = minDiff - 60 * diffObj.hours;
  return diffObj;
};

export const displayDate = (timestamp: number) => {
  const date = new Date(timestamp);
  return (
    date.toLocaleDateString("en-us", {
      month: "2-digit",
      day: "2-digit",
      year: "2-digit",
    }) +
    " " +
    date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
  );
};
