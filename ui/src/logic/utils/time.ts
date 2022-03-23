export const descriptiveTime = (time: number) => {
  let days = Math.ceil(time / 1000 / 60 / 60 / 24);
  if (days === 1) {
    return `${days} day`;
  } else if (days > 0) {
    return `${days} days`;
  } else {
    return `x hours left`;
  }
};

export const descriptiveTimeString = (start: number, end: number) => {
  let now = new Date().getTime();
  if (now < start) {
    let startsIn = start - now;
    return `Starts in ${descriptiveTime(startsIn)}`;
  }
  if (now > start && now < end) {
    let timeLeft = end - now;
    return `${descriptiveTime(timeLeft)} left`;
  }
};
