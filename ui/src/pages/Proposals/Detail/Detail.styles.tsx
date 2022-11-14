import { Flex, ThemeType } from "@holium/design-system";
import styled from "styled-components";
import { darken } from "polished";

interface SignalCardProps {
  theme: ThemeType;
}

export const DetailHeader = styled.header`
  border-bottom: 1px solid
    ${(props: SignalCardProps) => props.theme.colors.ui.input.borderColor};
  padding: 16px 16px 0 16px;
`;

export const DetailCentered = styled(Flex)`
  margin: 0 auto;
  display: flex;
  flex-direction: row;
  height: calc(100% - 30px);
  width: ${(props: SignalCardProps) => props.theme.breakpointsPx[4]}px;
  /* custom scrollbar */
`;

export const DetailBody = styled.div`
  /* &::-webkit-scrollbar {
    width: 20px;
  }

  &::-webkit-scrollbar-track {
    background-color: transparent;
  }

  &::-webkit-scrollbar-thumb {
    background-color: ${(props: SignalCardProps) =>
    props.theme.colors.bg.divider};
    border-radius: 16px;
    border: 6px solid transparent;
    background-clip: content-box;
    transition: 0.2s ease;

    &:hover {
      transition: 0.2s ease;
      background-color: ${(props: SignalCardProps) =>
    darken(0.025, props.theme.colors.bg.divider)};
    }
  } */
`;

export const ProposalResultSection = styled.div`
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  padding: 12px 20px;
  background: ${(props: SignalCardProps) => props.theme.colors.bg.inset};
  border-bottom: 1px solid
    ${(props: SignalCardProps) => props.theme.colors.ui.borderColor};
  box-sizing: border-box;
`;
