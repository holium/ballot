export const mapToList = (map: { [key: string]: any }) => {
  return map ? Object.keys(map).map((key: string) => map[key]) : [];
};
