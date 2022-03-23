import styled, { css } from "styled-components";
import { darken } from "polished";
import { Flex, Button, ThemeType } from "@holium/design-system";

export type StyleProps = {
  theme: ThemeType;
  additionalVariant?: "submit" | "option";
  chosenOption?: boolean;
  disabledButton?: boolean;
  width?: number;
  win?: boolean;
};

export const VoteCardButton = styled(Button)<StyleProps>`
  padding: 0px;
  width: 100%;
  border-radius: 3px;
  height: 32px;
  svg {
    width: 18px;
    height: 18px;
  }
  &:disabled {
    cursor: default;
    pointer-events: none;
    color: ${(props: StyleProps) => `${props.theme.colors.text.disabled}`};
    background: ${(props: StyleProps) => `${props.theme.colors.ui.disabled}25`};
  }
  ${(props) =>
    props.additionalVariant === "submit" &&
    css`
      margin-top: 12px;
      border: 1px solid ${(props) => props.theme.colors.brand.primary};
      background: ${(props) => props.theme.colors.brand.primary};
      color: ${(props) => props.theme.colors.text.white};
      cursor: pointer;
      &:hover {
        transition: 0.2s ease;
        background: ${(props) =>
          `${darken(0.05, props.theme.colors.brand.primary)}`};
      }
      &:disabled {
        margin-top: 12px;
        border: 1px solid ${(props) => props.theme.colors.brand.primary}25;
        background: ${(props) => `${props.theme.colors.brand.primary}15`};
        color: ${(props) => props.theme.colors.brand.primary};
        pointer-events: none;
      }
    `}

  ${(props) =>
    props.additionalVariant === "option" &&
    css`
      margin-top: 4px;
      border: 1px solid ${(props) => props.theme.colors.ui.borderColor};
      background: ${(props) => props.theme.colors.ui.quaternary};
      color: ${(props) => props.theme.colors.text.primary};
      cursor: pointer;
    `}
     ${(props) =>
    props.chosenOption === true &&
    css`
      border: 1px solid ${(props) => props.theme.colors.brand.primary};
      background: ${(props) => `${props.theme.colors.brand.primary}25`};
      color: ${(props) => props.theme.colors.brand.primary};
      pointer-events: none;
    `}
`;

export const Row = styled(Flex)<StyleProps>`
  width: 100%;
  justify-content: space-between;
  align-items: center;
  margin: 12px 0;
`;
