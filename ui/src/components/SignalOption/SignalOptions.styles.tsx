import { Card } from "@holium/design-system";
import styled from "styled-components";

type SignalCardProps = {
  selected: boolean;
};

export const SignalCard = styled(Card)`
  border: thin solid
    ${(props: SignalCardProps) =>
      props.selected === true
        ? props.theme.colors.brand.primary
        : props.theme.colors.ui.input.borderColor};
`;
