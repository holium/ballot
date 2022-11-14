import { useCallback, useEffect, useState } from "react";

interface useFetchState<T = any> {
  result: T;
  error: any;
  loading: boolean;
  fetched: boolean;
}

interface useFetchArgs<T> {
  fetchFn: (...args: any[]) => Promise<T>;
  fnArgs?: any[];
  immediate?: boolean;
}

const emptyArgs: any[] = [];

export const useFetch = <T>({
  fetchFn,
  fnArgs = emptyArgs,
  immediate = true,
}: useFetchArgs<T>) => {
  const [state, setState] = useState<useFetchState<any>>({
    result: null,
    error: null,
    loading: false,
    fetched: false,
  });

  const fetchRequest = useCallback(
    async (...extraArgs: any[]) => {
      setState((s) => ({ ...s, loading: true }));
      try {
        const data = await fetchFn(...fnArgs, ...extraArgs);
        if (data !== undefined) {
          setState((s) => ({ ...s, result: data }));
        }
      } catch (err) {
        setState((s) => ({ ...s, error: err }));
      } finally {
        setState((s) => ({ ...s, fetched: true, loading: false }));
      }
    },
    [fetchFn, fnArgs]
  );

  const makeRequest = async (...extraArgs: any[]) =>
    await fetchRequest(...extraArgs);

  useEffect(() => {
    if (!state.fetched && immediate) {
      fetchRequest();
    }
  }, [state.fetched, fetchRequest, immediate, fnArgs]);

  return { ...state, makeRequest };
};
