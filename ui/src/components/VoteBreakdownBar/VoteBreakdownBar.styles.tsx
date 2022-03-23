import { Flex } from "@holium/design-system";
import styled, { css } from "styled-components";

type BarProps = {
  win?: boolean;
  results?: number;
  overlay?: boolean;
  containerWidth?: string;
};

export const BarSet = styled.div<BarProps>`
  display: flex;
  flex-direction: column;
  width: 100%;
  margin-top: 4px;
  height: 32px;

  ${(props) =>
    props.overlay &&
    css`
      align-items: flex-start;
      position: relative;
    `}
`;

export const SideBySide = styled(Flex)`
  width: 100%;
  height: 100%;
  padding: 0 8px;
  justify-content: space-between;
  align-items: center;
`;

export const Bar = styled.div<BarProps>`
  ${(props) =>
    props.win === true
      ? css`
          background: ${(props) => `${props.theme.colors.brand.primary}50`};
          border: 1px solid
            ${(props) => `${props.theme.colors.brand.primary}25`};
        `
      : css`
          background: ${(props) => `${props.theme.colors.bg.primary}50`};
          border: 1px solid ${(props) =>
            `${props.theme.colors.brand.primary}50`}};
        `}
  ${(props) =>
    props.overlay &&
    css`
      position: absolute;
      z-index: 5;
    `}

  height: 32px;
  transition: width 0.3s;
  border-radius: 3px;
  box-sizing: border-box;
  width: ${(p: BarProps) => p.results}%;
`;
