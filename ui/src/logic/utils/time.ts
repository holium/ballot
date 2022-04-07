/**
 * TODO clean this logic up. All of it.
 *
 * @param param0: DateDiff
 * @returns
 */
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
      if (minutes > 0) {
        descriptiveString = `${minutes + 1} minutes`;
        // if (minutes === 1) {
        //   descriptiveString = `${minutes + 1} minute`;
        // }
      } else {
        descriptiveString = `less than a minute`;
      }
    }
  }
  return descriptiveString;
};

/**
 * Returns a descriptive string to be used for poll timers
 *
 * Examples:
 *   - 6 days left
 *   - 2 hours left
 *   - 5 minutes left
 *   - Starts in 6 days
 *   - Starts in 2 hours
 *   - Starts in 5 minutes
 *   - Starts in less than a minute
 *
 * @param {number} start
 * @param {number} end
 * @return {*}  {({ timeString: string; timerInterval: number | null })}
 */
export const descriptiveTimeString = (
  start: number,
  end: number
): { timeString: string; timerInterval: number | null } => {
  let now = new Date().getTime();
  start = start * 1000;
  end = end * 1000;
  let timeString;
  let dateDiff: DateDiff = {
    hours: 0,
    minutes: 0,
    days: 0,
    seconds: 0,
  };
  // console.log(now, start, end);
  if (now < start) {
    dateDiff = getDateDiff(now, start);
    timeString = `Starts in ${descriptiveTime(dateDiff)}`;
  } else if (now > start && now < end) {
    dateDiff = getDateDiff(now, end);
    timeString = `${descriptiveTime(dateDiff)} left`;
  } else {
    timeString = "Closed";
  }
  let timerInterval = getTimerInterval(dateDiff);
  // console.log(timerInterval);
  return { timeString, timerInterval };
};

type DateDiff = {
  hours: number;
  minutes: number;
  days: number;
  seconds: number;
};

/**
 * Calculates the time between start and end.
 *
 * @param {number} start
 * @param {number} end
 * @return {*}  {DateDiff}
 */
export const getDateDiff = (start: number, end: number): DateDiff => {
  var timeDiff = end - start;
  let dayDiff = Math.floor(timeDiff / 1000 / 60 / 60 / 24);
  var minDiff = Math.floor(timeDiff / 60 / 1000);
  var hourDiff = timeDiff / 3600 / 1000;
  var secDiff = Math.floor(timeDiff / 1000);
  var diffObj: DateDiff = {
    hours: 0,
    minutes: 0,
    days: dayDiff,
    seconds: secDiff,
  };
  diffObj.days = dayDiff;
  diffObj.hours = Math.floor(hourDiff) - 24 * diffObj.days;
  diffObj.minutes = minDiff - 60 * Math.floor(hourDiff);
  diffObj.seconds = secDiff - 60 * Math.floor(minDiff);
  return diffObj;
};

/**
 * Gets a display date in the following format:
 *  04/07/22 05:47 AM
 *
 * @param {number} timestamp
 * @return {*}  {string}
 */
export const displayDate = (timestamp: number): string => {
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

// Interval map for reference
const timeIntervalMap = {
  day: 86400000,
  hour: 3600000,
  minute: 60000,
  second: 1000,
};

/**
 * Gets an interval that will tell a timer to fire. Used to re-render
 * the time string in ProposalCards and the Detail page.
 *
 * @param {DateDiff} dateDiff
 * @return {*}  {number | null}
 */
const getTimerInterval = (dateDiff: DateDiff): number | null => {
  //
  if (dateDiff.days > 0) {
    // the hours variable will have remaining hours for the day
    // ie.
    //  dateDiff.hours = 21  - hours left in the current day
    //  timeIntervalMap.hour - hours in milliseconds
    //
    //  by multiplying these together, it will make the timer fire
    //  again in 21 hours to refresh for the next day.
    //
    return (
      dateDiff.hours * timeIntervalMap.hour +
      dateDiff.minutes * timeIntervalMap.minute +
      dateDiff.seconds * timeIntervalMap.second
    );
  } else if (dateDiff.hours > 0) {
    // gives the amount of minutes left in the hour so the timer
    // can refresh on the hour
    return (
      dateDiff.minutes * timeIntervalMap.minute +
      dateDiff.seconds * timeIntervalMap.second +
      timeIntervalMap.minute
    );
  } else if (dateDiff.minutes > 0) {
    // gives the amount of seconds left in a minute so the timer
    // can refresh on the minute
    const secondsLeft = dateDiff.seconds || 59;
    return secondsLeft * timeIntervalMap.second + timeIntervalMap.second;
  } else if (dateDiff.seconds > 0) {
    const secondsLeft = dateDiff.seconds || 59;
    return secondsLeft * timeIntervalMap.second + timeIntervalMap.second;
  } else {
    return null;
  }
};
