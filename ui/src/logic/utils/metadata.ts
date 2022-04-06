import { BoothModelType } from "./../stores/booths/booth";
export const getBoothName = (booth: BoothModelType) => {
  if (booth.type === "group") {
    // @ts-expect-error
    return booth.meta.title || booth.name;
  } else if (booth.type === "ship") {
    // @ts-expect-error
    return booth.meta.nickname || booth.name;
  } else {
    booth.name;
  }
};
