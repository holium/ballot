export const timeout = async (ms: number) => {
  return await new Promise((resolve) => setTimeout(resolve, ms));
};
